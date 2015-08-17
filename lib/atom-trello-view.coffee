{SelectListView} = require 'atom-space-pen-views'
{$} = require 'space-pen'
Shell = require 'shell'

module.exports =

class AtomTrelloView extends SelectListView
  api: null
  elem: null
  backBtn: null
  activeBoards: null
  activeLanes: null
  currentView: 'boards'
  user: null
  avatarUrl: "https://trello-avatars.s3.amazonaws.com/"

  initialize: () ->
    super
    @getFilterKey = () ->
      return 'name'

    @addClass('atom-trello overlay from-top')
    @panel ?= atom.workspace.addModalPanel(item: this)
    @elem = $(@panel.item.element)

    @setButtons()

  setApi: (api) ->
    @api = api

  setUser: (user) ->
    @user = user

  viewForItem: (item) ->
    switch @currentView
      when 'cards' then @cardsView(item)
      else @defaultView(item)

  defaultView: (item) ->
    "<li>#{item.name}</li>"

  cardsView: (item) ->
    avatars = () =>
      avatarString = ""
      item.members.map (obj) =>
        if obj.avatarHash
          avatarString += "<img class='at-avatar' src='#{@getAvatar obj.avatarHash}'/>"
        else
          avatarString += "<span class='at-avatar no-img'>#{obj.initials}</span>"
      return avatarString

    if @filterMyCards and @user.id not in item.idMembers
      return false

    "<li class='two-lines'>
        <div class='primary-line'>
          <div class='at-title'>#{item.name}</div>
          <div class='at-avatars'>#{avatars()}</div>
        </div>
        <div class='secondary-line'>#{item.desc}</div>
    </li>"

  showView: (items, showBackBtn = true) ->
    @setItems(items)
    @focusFilterEditor()
    if showBackBtn then @backBtn.show() else @backBtn.hide()

  loadBoards: () ->
    @currentView = 'boards'
    @activeLanes = null
    @panel.show()
    @backBtn.hide()
    @setLoading "Your Boards are Loading!"

    @confirmed = (board) =>
      @cancel()
      @loadLanes(board)

    if @activeBoards
      @showView @activeBoards, false
      return

    @api.get '/1/members/me/boards', { filter: "open" }, (err, data) =>
      @activeBoards = data;
      @showView @activeBoards, false

  loadLanes: (board) ->
    @currentView = 'lanes'
    @panel.show()
    @backBtn.hide()
    @setLoading "Your Lanes are Loading!"

    @confirmed = (lane) =>
      @cancel()
      @loadCards(lane)

    if @activeLanes
      @showView(@activeLanes)
      @backBtn.show()
      return

    @api.get "/1/boards/" + board.id + '/lists', {cards: "open"} ,(err, data) =>
      @activeLanes = data
      @activeCards = null
      @showView(@activeLanes)

  loadCards: (lane) ->
    @currentView = 'cards'
    @panel.show()
    @backBtn.hide()
    @setLoading "Your Cards are Loading!"

    @confirmed = (card) =>
      Shell.openExternal(card.url)

    user = @user

    @api.get "/1/lists/#{lane.id}/cards", { filter: "open", members: true }, (err, data) =>
      activeCards = data

      @showView(activeCards)

  cardActions: (card) ->
    @currentView = 'card'
    @panel.show()
    @setLoading "Loading Card"
    @api.get "/1/cards/" + card.id, (err, data) =>
      console.log data

  setButtons: () ->
    @backBtn = $("<div id='back_btn' class='block'><button class='btn icon icon-arrow-left inline-block-tight'>Back</button></div>")
    @backBtn
      .appendTo(@elem)
      .hide()
      .on 'mousedown', (e) =>
        e.preventDefault()
        e.stopPropagation()
        @cancel()
        switch @currentView
          when 'card' then @loadCards()
          when 'cards' then @loadLanes()
          when 'lanes' then @loadBoards()
          else @loadBoards()

    @cardFilter = $('<div class="settings-view at-filter"><div class="checkbox"><input id="atomTrello_cardFilter" type="checkbox"><div class="setting-title">show only cards assigned to me</div></div></div>')
    @cardFilterInput = @cardFilter.find('input')
    @cardFilter.appendTo(@elem)

    @cardFilter
      .on 'mousedown', (e) =>
        e.preventDefault()
        e.stopPropagation()
        @filterMyCards = !@cardFilterInput.prop('checked')
        @cardFilterInput.prop('checked', @filterMyCards)
        @populateList()
      .find('input').on 'click change', (e) =>
        e.preventDefault()
        e.stopPropagation()

  getAvatar: (id, large = false) ->
    size = if large then '170' else '30'
    return @avatarUrl + id + "/#{size}.png"

  cancelled: ->
    @panel.hide()
