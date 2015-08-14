{SelectListView} = require 'atom-space-pen-views'
CardsView = require './cards-view'
Trello = require 'node-trello'

module.exports =
class LanesView extends SelectListView
  initialize: (board) ->
    super

    self = @

    @getFilterKey = () ->
      return 'name'

    @addClass('overlay from-top')
    @panel ?= atom.workspace.addModalPanel(item: this)

    t = new Trello '6598ad858d58b2371b5ace323a1b5d20', '5b84dee1ab57bfdb4bb814807d1524d7905845ddf1cf1b896c4e19c004860a83'

    t.get "/1/boards/" + board.id + '/lists', {cards: "open"} ,(err, data) ->
      self.setItems(data)
      self.panel.show()
      self.focusFilterEditor()

  viewForItem: (lane) ->
    "<li>#{lane.name}</li>"

  confirmed: (lane) ->
    cardsView = new CardsView(lane)
    
  cancelled: ->
    @panel.hide()
