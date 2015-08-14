AtomTrelloView = require './atom-trello-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomTrello =
  subscriptions: null
  atomTrelloView: null

  activate: (state) ->
    console.log 'activating'
    @atomTrelloView = new AtomTrelloView()
    @subscriptions = new CompositeDisposable
    @atomTrelloView.loadBoards()
    @atomTrelloView.panel.hide()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-trello:boards': => @boards()

  deactivate: ->
    console.log 'deactivating'
    @subscriptions.dispose()
    @atomTrelloView.destroy()

  # serialize: ->
  #   atomTestViewState: @atomTestView.serialize()

  boards: ->
    if @atomTrelloView.panel.isVisible()
      @atomTrelloView.panel.hide()
    else
      @atomTrelloView.panel.show()
      @atomTrelloView.populateList()
      @atomTrelloView.focusFilterEditor()
