{SelectListView} = require 'atom-space-pen-views'
Trello = require 'node-trello'

module.exports =
class CardsView extends SelectListView
  initialize: (lane) ->
    super

    self = @

    @getFilterKey = () ->
      return 'name'

    @addClass('overlay from-top')

    @panel ?= atom.workspace.addModalPanel(item: this)

    t = new Trello '6598ad858d58b2371b5ace323a1b5d20', '5b84dee1ab57bfdb4bb814807d1524d7905845ddf1cf1b896c4e19c004860a83'

    t.get "/1/members/me", { cards: "open" }, (err, data) ->
      activeCards = data.cards.filter (card) ->
        return card.idList == lane.id

      self.setItems(activeCards)
      self.panel.show()
      self.focusFilterEditor()

  viewForItem: (item) ->
    "<li>#{item.name}</li>"

  confirmed: (item) ->
    console.log item
    @panel.hide()

  cancelled: ->
    @panel.hide()
