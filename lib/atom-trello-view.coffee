{SelectListView} = require 'atom-space-pen-views'
{$} = require 'space-pen'
Trello = require 'node-trello'

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

    @trl = new Trello '6598ad858d58b2371b5ace323a1b5d20', '5b84dee1ab57bfdb4bb814807d1524d7905845ddf1cf1b896c4e19c004860a83'

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

  viewForItem: (item) ->
    "<li>#{item.name}</li>"

  showView: (items) ->
    @setItems(items)
    @focusFilterEditor()

  loadBoards: () ->
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
        console.log card
        @cancel()

  cancelled: ->
    @panel.hide()
