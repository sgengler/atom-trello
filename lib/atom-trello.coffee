AtomTrelloView = require './atom-trello-view'
http = require('http')
OAuth = require('oauth').OAuth
url = require('url')
{CompositeDisposable} = require 'atom'

module.exports = AtomTrello =
  subscriptions: null
  atomTrelloView: null
  hasLoaded: false
  trl: null

  config: {
    devKey:
      title: "Trello Developer Key"
      description: "get key at https://trello.com/1/appKey/generate"
      type: "string"
      default: ""
    token:
      title: "Token"
      description: "Add developer key and you will be redirected to get your token. Paste below."
      type: "string"
      default: ""
  }

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-trello:toggle': => @toggle()

  deactivate: ->
    @subscriptions.dispose()
    @atomTrelloView.destroy()

  # serialize: ->
  #   atomTestViewState: @atomTestView.serialize()

  toggle: ->
    if !@setApiKeys
      atom.notifications.addWarning 'Please enter your Trello key and token in the settings'
      return

    if !@hasLoaded
      @atomTrelloView = new AtomTrelloView()
      @atomTrelloView.loadBoards()
      @atomTrelloView.panel.show()
      @atomTrelloView.populateList()
      @atomTrelloView.focusFilterEditor()
      @hasLoaded = true
      return

    if @atomTrelloView.panel.isVisible()
      @atomTrelloView.panel.hide()
    else
      @atomTrelloView.panel.show()
      @atomTrelloView.populateList()
      @atomTrelloView.focusFilterEditor()

  setApi: () ->
    atom.config.onDidChange 'atom-trello.devKey', ({newValue, oldValue}) =>
      if newValue and !atom.config.get('atom-trello.token')
        Shell.openExternal("https://trello.com/1/connect?key=#{newValue}&name=AtomTrello&response_type=token&scope=read,write&expiration=never")
      else
        @sendWelcome () => @setApiConfig()

    atom.config.onDidChange 'atom-trello.token', ({newValue, oldValue}) =>
      @setApiKeys
      @sendWelcome () => @setApiConfig()

    if !@setApiKeys()
      atom.notifications.addWarning 'Please enter your Trello key and token in the settings'
    else
      @setApiConfig()

  setApiKeys: () ->
    @devKey = atom.config.get('atom-trello.devKey')
    @token = atom.config.get('atom-trello.token')

    if !@devKey || !@token
      return false

    @trl = new Trello @devKey, @token
    return true

  sendWelcome: (callback) =>

    @trl.get '/1/members/me', (err, data) =>
      if err?
        atom.notifications.addError 'Failed to set Trello API, check your credentials'
        return
      if data.username
        atom.notifications.addSuccess "Hey #{data.fullName} you're good to go!"
        if callback
          callback()
