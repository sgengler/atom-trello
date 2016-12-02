AtomTrelloView = require './atom-trello-view'
Trello = require 'node-trello'
Shell = require 'shell'
{CompositeDisposable} = require 'atom'

module.exports = AtomTrello =
  subscriptions: null
  atomTrelloView: null
  hasLoaded: false
  api: null

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
    @settingsInit()
    @subscriptions.add atom.commands.add 'atom-workspace', 'atom-trello:toggle': => @toggle()

  deactivate: ->
    @subscriptions.dispose()
    @atomTrelloView.destroy()

  # serialize: ->
  #   atomTestViewState: @atomTestView.serialize()

  initializePackage: () ->
    @atomTrelloView = new AtomTrelloView()
    @setApi()
    @atomTrelloView.setApi @api
    @getUser (data) =>
      @atomTrelloView.setUser data
    @atomTrelloView.loadBoards()
    @hasLoaded = true

  toggle: ->
    if !@setApi() or !@api
      atom.notifications.addWarning 'Please enter your Trello key and token in the settings'
      return

    if !@hasLoaded
      @initializePackage()
      return

    if @atomTrelloView.panel.isVisible()
      @atomTrelloView.panel.hide()
    else
      @atomTrelloView.panel.show()
      @atomTrelloView.populateList()
      @atomTrelloView.focusFilterEditor()

  settingsInit: () ->
    atom.config.onDidChange 'atom-trello.devKey', ({newValue, oldValue}) =>
      if newValue and !atom.config.get('atom-trello.token')
        Shell.openExternal("https://trello.com/1/connect?key=#{newValue}&name=AtomTrello&response_type=token&scope=read,write&expiration=never")
      else
        @sendWelcome()

    atom.config.onDidChange 'atom-trello.token', ({newValue, oldValue}) =>
      if newValue
        @sendWelcome()

  setApi: () ->
    @devKey = atom.config.get('atom-trello.devKey')
    @token = atom.config.get('atom-trello.token')

    if !@devKey || !@token
      return false

    @api = new Trello @devKey, @token
    return true

  getUser: (callback) ->
    @api.get '/1/members/me', (err, data) =>
      if err?
        atom.notifications.addError 'Failed to set Trello API, check your credentials'
        @api = null
        return
      if data.username
        if callback
          callback(data)

  sendWelcome: (callback) ->
    if !@setApi()
      return
    @getUser (data) ->
      if data.username
        atom.notifications.addSuccess "Hey #{data.fullName} you're good to go!"
        if callback
          callback()
