{SelectListView} = require 'atom-space-pen-views'
{$} = require 'space-pen'
Trello = require 'node-trello'

module.exports =
class AtomTrelloView extends SelectListView
  trl: null
  elem: null
  backBtn: null
  initialize: () ->
    super

    self = @
    @trl = new Trello '6598ad858d58b2371b5ace323a1b5d20', '5b84dee1ab57bfdb4bb814807d1524d7905845ddf1cf1b896c4e19c004860a83'

    @getFilterKey = () ->
      return 'name'

    @addClass('atom-trello overlay from-top')
    @panel ?= atom.workspace.addModalPanel(item: this)

    @elem = $(@panel.item.element)

    @backBtn = $("<div id='back_btn' class='block'><button class='btn icon icon-arrow-left inline-block-tight'>Back</button></div>")

    @backBtn.appendTo(@elem).hide()

    @backBtn.on 'mousedown', (e) ->
      e.preventDefault()
      e.stopPropagation()
      self.cancel()
      self.loadBoards()

  viewForItem: (item) ->
    "<li>#{item.name}</li>"

  loadBoards: () ->
    self = @
    @panel.show()
    @backBtn.hide()
    @setLoading "Your Boards are Loading!"
    @trl.get '/1/members/me/boards', { filter: "open" }, (err, data) ->
      self.setItems(data)
      self.focusFilterEditor()
      self.confirmed = (board) ->
        self.cancel()
        self.loadLanes(board)

  loadLanes: (board) ->
    self = @
    @panel.show()
    @setLoading "Your Lanes are Loading!"

    @trl.get "/1/boards/" + board.id + '/lists', {cards: "open"} ,(err, data) ->
      self.setItems(data)
      self.panel.show()
      self.focusFilterEditor()
      self.backBtn.show()
      self.confirmed = (lane) ->
        console.log 'selected'
        self.cancel()
        self.loadCards(lane)

  loadCards: (lane) ->
    self = @
    @panel.show()
    @setLoading "Your Cards are Loading!"
    @trl.get "/1/members/me", { cards: "open" }, (err, data) ->
      activeCards = data.cards.filter (card) ->
        return card.idList == lane.id

      self.setItems(activeCards)
      self.panel.show()
      self.focusFilterEditor()

      self.confirmed = (card) ->
        self.cancel()

  cancelled: ->
    @panel.hide()
