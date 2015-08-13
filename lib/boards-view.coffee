{SelectListView} = require 'atom-space-pen-views'
LanesView = require './lanes-view'
Trello = require 'node-trello'

module.exports =
class BoardsView extends SelectListView
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

    @activeCards = null
    t.get "/1/boards/" + item.id + '/lists', {cards: "open"} ,(err, data) ->
      lanesView = new LanesView()
      lanesView.setItems(data)

  cancelled: ->
    @panel.hide()
