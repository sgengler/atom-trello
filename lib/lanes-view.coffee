{SelectListView} = require 'atom-space-pen-views'
CardsView = require './cards-view'
Trello = require 'node-trello'

module.exports =
class LanesView extends SelectListView
  initialize: () ->
    super

    @getFilterKey = () ->
      return 'name'

    @addClass('overlay from-top')

    @panel ?= atom.workspace.addModalPanel(item: this)
    @panel.show()
    @focusFilterEditor()

  viewForItem: (item) ->
    "<li>#{item.name}</li>"

  confirmed: (item) ->
    t = new Trello '6598ad858d58b2371b5ace323a1b5d20', '5b84dee1ab57bfdb4bb814807d1524d7905845ddf1cf1b896c4e19c004860a83'
    t.get "/1/members/me", { cards: "open" }, (err, data) ->
      console.log 'cards:'
      activeCards = data.cards.filter (card) ->
        return card.idList == item.id

      cardsView = new CardsView()
      cardsView.setItems(activeCards)
  cancelled: ->
    @panel.hide()
