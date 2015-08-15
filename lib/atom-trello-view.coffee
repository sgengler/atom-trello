{SelectListView} = require 'atom-space-pen-views'
{$} = require 'space-pen'
Trello = require 'node-trello'
Shell = require 'shell'

module.exports =

class AtomTrelloView extends SelectListView
  trl: null
  elem: null
  backBtn: null
  activeBoards: null
  activeLanes: null

  initialize: () ->
    super
    @getFilterKey = () ->
      return 'name'

    @addClass('atom-trello overlay from-top')
    @panel ?= atom.workspace.addModalPanel(item: this)
    @elem = $(@panel.item.element)
    @backBtn = $("<div id='back_btn' class='block'><button class='btn icon icon-arrow-left inline-block-tight'>Back</button></div>")
    @backBtn.appendTo(@elem).hide()

    @setApi()

    @backBtn.on 'mousedown', (e) =>
      e.preventDefault()
      e.stopPropagation()
      @cancel()
      if @activeLanes
        @loadLanes()
        @activeLanes = null
      else
        @loadBoards()

  setApi: () ->
    @setApiConfig = () =>
      if !@setApiKeys()
        return

      @activeBoards = null
      @cancel()
      @loadBoards()
      @panel.hide()

    atom.config.onDidChange 'atom-trello.devKey', ({newValue, oldValue}) =>
      if newValue and !atom.config.get('atom-trello.token')
        Shell.openExternal("https://trello.com/1/connect?key=#{newValue}&name=AtomTrello&response_type=token&scope=read,write&expiration=never")
      else
        @sendWelcome () => @setApiConfig()

    atom.config.onDidChange 'atom-trello.token', ({newValue, oldValue}) =>
      @sendWelcome () => @setApiConfig()

    @setApiConfig()

  setApiKeys: () ->
    @devKey = atom.config.get('atom-trello.devKey')
    @token = atom.config.get('atom-trello.token')

    if !@devKey || !@token
      return false

    @trl = new Trello @devKey, @token
    return true

  sendWelcome: (callback) =>
    if !@setApiKeys()
      atom.notifications.addWarning 'Please enter your Trello key and token in the settings'
      return

    @trl.get '/1/members/me', (err, data) =>
      if err?
        atom.notifications.addError 'Failed to set Trello API, check your credentials'
        return
      if data.username
        atom.notifications.addSuccess "Hey #{data.fullName} you're good to go!"
        if callback
          callback()

  viewForItem: (item) ->
    if item.desc?
      "<li class='two-lines'>
          <div class='primary-line'>#{item.name}</div>
          <div class='secondary-line'>#{item.desc}</div>
      </li>"
    else
      "<li>#{item.name}</li>"

  showView: (items) ->
    @setItems(items)
    @focusFilterEditor()

  loadBoards: () ->
    if !@trl
      return

    self = @
    @panel.show()
    @backBtn.hide()
    @setLoading "Your Boards are Loading!"

    @confirmed = (board) =>
      @cancel()
      @loadLanes(board)

    if @activeBoards
      @showView(@activeBoards)
      return

    @trl.get '/1/members/me/boards', { filter: "open" }, (err, data) =>
      @activeBoards = data;
      @showView(@activeBoards)

  loadLanes: (board) ->
    @panel.show()
    @setLoading "Your Lanes are Loading!"

    @confirmed = (lane) =>
      @cancel()
      @loadCards(lane)

    if @activeLanes
      @showView(@activeLanes)
      @backBtn.show()
      return

    @trl.get "/1/boards/" + board.id + '/lists', {cards: "open"} ,(err, data) =>
      @activeLanes = data
      @showView(@activeLanes)
      @backBtn.show()

  loadCards: (lane) ->
    @panel.show()
    @setLoading "Your Cards are Loading!"
    @trl.get "/1/members/me", { cards: "open" }, (err, data) =>
      activeCards = data.cards.filter (card) ->
        return card.idList == lane.id

      @setItems(activeCards)
      @panel.show()
      @focusFilterEditor()

      @confirmed = (card) =>
        Shell.openExternal(card.url)

  cardActions: (card) ->
    @panel.show()
    @setLoading "Loading Card"
    @trl.get "/1/cards/" + card.id, (err, data) =>
      console.log data

  cancelled: ->
    @panel.hide()
