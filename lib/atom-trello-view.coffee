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
    if item.desc?
      "<li class='two-lines'>
          <div class='primary-line'>#{item.name}</div>
          <div class='secondary-line'>#{item.desc}</div>
      </li>"
    else
      "<li>#{item.name}</li>"

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
      @showView(@activeLanes)

  loadCards: (lane) ->
    @currentView = 'cards'
    @panel.show()
    @backBtn.hide()
    @setLoading "Your Cards are Loading!"

    @confirmed = (card) =>
      Shell.openExternal(card.url)

    console.log @user.id

    @api.get "/1/lists/#{lane.id}/cards", { filter: "open" }, (err, data) =>
      activeCards = data
      @showView(activeCards)
      console.log data

    # @api.get "/1/members/me", { cards: "open" }, (err, data) =>
    #   activeCards = data.cards.filter (card) ->
    #     return card.idList == lane.id
    #   @showView(activeCards)

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

    @cardFilter = $('<div class="settings-view"><div class="checkbox"><input id="atomTrello_cardFilter" type="checkbox"><div class="setting-title">show only cards assigned to me</div></div></div>')
    @cardFilterInput = @cardFilter.find('input')
    @cardFilter.appendTo(@elem)

    @cardFilter
      .on 'mousedown', (e) =>
        e.preventDefault()
        e.stopPropagation()
        checkstate = !@cardFilterInput.prop('checked')
        @cardFilterInput.prop('checked', checkstate)
      .find('input').on 'click change', (e) =>
        e.preventDefault()
        e.stopPropagation()

  cancelled: ->
    @panel.hide()
