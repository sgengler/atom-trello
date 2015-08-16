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

  initialize: () ->
    super
    @getFilterKey = () ->
      return 'name'

    @addClass('atom-trello overlay from-top')
    @panel ?= atom.workspace.addModalPanel(item: this)
    @elem = $(@panel.item.element)
    @backBtn = $("<div id='back_btn' class='block'><button class='btn icon icon-arrow-left inline-block-tight'>Back</button></div>")
    @backBtn.appendTo(@elem).hide()

    @backBtn.on 'mousedown', (e) =>
      e.preventDefault()
      e.stopPropagation()
      @cancel()
      if @activeLanes
        @loadLanes()
        @activeLanes = null
      else
        @loadBoards()

  setApi: (api) ->
    @api = api

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
    @backBtn.hide()
    @setLoading "Your Boards are Loading!"

    @confirmed = (board) =>
      @cancel()
      @loadLanes(board)

    if @activeBoards
      @showView(@activeBoards)
      return

    @api.get '/1/members/me/boards', { filter: "open" }, (err, data) =>
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

    @api.get "/1/boards/" + board.id + '/lists', {cards: "open"} ,(err, data) =>
      @activeLanes = data
      @showView(@activeLanes)
      @backBtn.show()

  loadCards: (lane) ->
    @panel.show()
    @setLoading "Your Cards are Loading!"
    @api.get "/1/members/me", { cards: "open" }, (err, data) =>
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
    @api.get "/1/cards/" + card.id, (err, data) =>
      console.log data

  cancelled: ->
    @panel.hide()
