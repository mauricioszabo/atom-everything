{SelectListView} = require 'atom-space-pen-views'

class EverythingView extends SelectListView
  timeout: 0
  providers: {}
  lastQuery = ""

  initialize: ->
    super
    @addClass('overlay from-top')
    @setItems(['Hello', 'World', "Hello, World!"])
    atom.workspaceView.append(this)

  cancelled: ->
    @hide()

  viewForItem: (item) ->
    if item.additionalInfo
      "<li>#{item.displayName} <div class='pull-right key-binding'>" +
        item.additionalInfo + "</div></li>"
    else
      "<li>#{item.displayName}</li>"

  confirmed: (item) ->
    console.log(item)
    console.log(item.function)
    item.function()
    @hide()

  getFilterKey: -> "displayName"

  registerProvider: (name, fn, whenToRun = -> true) ->
    @providers[name] = {
      function: fn,
      willRun: whenToRun
    }

  getFilterQuery: ->
    query = super
    return query if query == lastQuery
    lastQuery = query
    @updateResults(query)
    query

  updateResults: (query) ->
    @setItems([])
    for name, provider of @providers when provider.willRun(query)
      provider.function(query).then (items) =>
        @appendItems(items)
    null


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

  appendItems: (items) ->
    @setItems(items.concat(@items))

  show: ->
    @filterEditorView.setText(lastQuery)
    super
    @updateResults(lastQuery)
    @filterEditorView.model.selectAll()
    @focusFilterEditor()

module.exports = EverythingView

window.M = EverythingView
