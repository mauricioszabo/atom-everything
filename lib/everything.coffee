EverythingView = require './everything-view'
CommandsProvider = require './commands-provider'

module.exports = Everything =
  evr: null

  providers: [
    new CommandsProvider()
  ]

  activate: (state) ->
    atom.commands.add 'atom-workspace', 'everything:fuzzy-finder', => @showEverything()

  simpleSearcher: (provider) ->
    @providers.push(provider)

  showEverything: ->
    if !@evr
      @evr ?= new EverythingView()
      for provider in @providers
        shouldRun = provider.shouldRun
        shouldRun ?= -> true
        @evr.registerProvider(provider.name, provider.function, shouldRun)
    @evr.show()
