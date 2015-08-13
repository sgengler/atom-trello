{SelectListView} = require 'atom-space-pen-views'

module.exports =
class CardsView extends SelectListView
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
    console.log item
    @panel.hide()

  cancelled: ->
    @panel.hide()
