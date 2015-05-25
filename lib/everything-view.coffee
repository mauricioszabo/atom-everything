{SelectListView} = require 'atom-space-pen-views'

class EverythingView extends SelectListView
  initialize: ->
    super
    @addClass('overlay from-top')
    @setItems(['Hello', 'World', "Hello, World!"])
    atom.workspaceView.append(this)
    @focusFilterEditor()
    @registerProvider 'hello', (search) ->
      new Promise (resolve) ->
        resolve([
          { displayName: "Hello, #{search}" }
          { displayName: "Help, #{search}" }
        ])

    @registerProvider 'commands', (search) -> new Promise (resolve) ->
      view = atom.views.getView(atom.workspace.getActiveTextEditor())
      commands = atom.commands.findCommands(target: view)
      resolve(commands)
      
  timeout: 0
  providers: {}
  lastQuery: null

  cancelled: -> @hide()

  viewForItem: (item) ->
    "<li>#{item.displayName}</li>"

  confirmed: (item) ->
    console.log("#{item} was selected")
    @hide()

  getFilterKey: -> "displayName"

  registerProvider: (name, fn, whenToRun = -> true) ->
    @providers[name] = {
      function: fn,
      willRun: whenToRun
    }

  getFilterQuery: ->
    query = super
    return query if query == @lastQuery
    @lastQuery = query

    @setItems([])
    for name, provider of @providers when provider.willRun(query)
      provider.function(query).then (items) =>
        @appendItems(items)

    # @timeout = setTimeout =>
    #   return if query.length == 0
    #   @setItems(["algo", "nada", "zero"])
    #   # console.log("http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=#{query}")
    #   # getJSON "http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=#{query}", (json) =>
    #   #   console.log("SET ITEMS!")
    #   #   console.log(json)
    #   #   items = json.responseData.results.map (data) =>
    #   #     data.titleNoFormatting
    #   #   console.log(items)
    #   #
    #   #   @setItems(items.concat(@items))
    # , 100
    query

  appendItems: (items) ->
    @setItems(items.concat(@items))

module.exports = EverythingView

window.M = EverythingView
