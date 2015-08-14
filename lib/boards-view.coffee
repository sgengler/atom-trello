{SelectListView} = require 'atom-space-pen-views'
LanesView = require './lanes-view'
Trello = require 'node-trello'

module.exports =
class BoardsView extends SelectListView
  trl = null

  initialize: (trl) ->
    super
    self = @

    @trl = trl

    @getFilterKey = () ->
      return 'name'

    @addClass('overlay from-top')
    @setLoading "Your Boards are Loading!"
    @panel ?= atom.workspace.addModalPanel(item: this, visible: false)

    @trl.get '/1/members/me/boards', { filter: "open" }, (err, data) ->
      self.setItems(data)
      self.focusFilterEditor()

  viewForItem: (board) ->
    "<li>#{board.name}</li>"

  confirmed: (board) ->
    @lanesView = new LanesView(board)

  cancelled: ->
    @panel.hide()
