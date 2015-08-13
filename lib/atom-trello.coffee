BoardsView = require './boards-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomTrello =
  modalPanel: null
  subscriptions: null
  boardsView: null
  boards: null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-trello:boards': => @boards()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @boardsView.destroy()

  # serialize: ->
  #   atomTestViewState: @atomTestView.serialize()

  boards: ->
    console.log 'starting boards'

    Trello = require 'node-trello'
    t = new Trello '6598ad858d58b2371b5ace323a1b5d20', '5b84dee1ab57bfdb4bb814807d1524d7905845ddf1cf1b896c4e19c004860a83'

    t.get '/1/members/me/boards', { filter: "open" }, (err, data) ->
      console.log data
      @boardData = data
      boards = new BoardsView()
      boards.setItems(@boardData)

    t.get "/1/members/me", { cards: "open" }, (err, data) ->
      console.log(data);

    # if @modalPanel.isVisible()
    #   @modalPanel.hide()
    # else
    #   @modalPanel.show()
