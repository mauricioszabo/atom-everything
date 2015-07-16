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
    new CommandsProvider()
    new GoogleProvider()
  ]

  activate: (state) ->
    atom.commands.add 'atom-workspace', 'everything:fuzzy-finder', => @showEverything()

  simpleSearcher: (provider) ->
    @providers.push(provider)

  showEverything: ->
    if !@evr
      @evr ?= new EverythingView()
      for provider in @providers
        provider.shouldRun ?= -> true
        @evr.registerProvider(provider)
    @evr.show()
    window.evr = @evr
