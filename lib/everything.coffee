EverythingView = require './everything-view'
CommandsProvider = require './commands-provider'
GoogleProvider = require './google-provider'

module.exports =
  config:
    showProvidersName:
      type: 'boolean'
      default: true

  evr: null

  providers: [
  ]

  activate: (state) ->
    atom.commands.add 'atom-workspace', 'everything:fuzzy-finder', => @showEverything()

  simpleSearcher: (provider) ->
    provider.onQuery = provider.function
    provider.shouldRun ?= -> true
    @getEvr().registerProvider(provider)

  streamSearcher: (provider) ->
    provider.shouldRun ?= -> true
    @getEvr().registerProvider(provider)

  showEverything: ->
    @getEvr().show()

  getEvr: ->
    @evr ?= do =>
      e = new EverythingView()
      p = new CommandsProvider()
      p.shouldRun ?= -> true
      e.registerProvider(p)
      p = new GoogleProvider()
      p.shouldRun ?= -> true
      e.registerProvider(p)
      e
