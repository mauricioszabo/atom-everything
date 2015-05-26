{SelectListView} = require 'atom-space-pen-views'
{filter, match} = require 'fuzzaldrin'

class EverythingView extends SelectListView
  timeout: 0
  providers: {}
  lastQuery = ""

  initialize: ->
    super
    @addClass('overlay from-top everything')
    atom.workspaceView.append(this)
    @on 'keydown', (evt) => console.log(evt)

  cancelled: ->
    @hide()

  viewForItem: (item) ->
    addInfo = item.additionalInfo
    addInfo = if addInfo then [].concat(addInfo) else []
    addTags = addInfo.map (e) => "<div class='pull-right key-binding'>#{e}</div>"

    matches = match(item.displayName, lastQuery)

    display = for char, i in item.displayName.split("")
      if matches.indexOf(i) == -1
        char
      else
        "<b>#{char}</b>"

    "<li>#{display.join("")}#{addTags.join(" ")}</li>"

  confirmed: (item) ->
    item.function()
    @hide()

  getFilterKey: -> "queryString"

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
      do =>
        span = @find("span[data-provider='#{name}']")
        if span.length == 0
          @append("<span class='key-binding' data-provider='#{name}'>#{name}</span>")
          span = @find("span[data-provider='#{name}']")

        provider.function(query).then (items) =>
          span.detach()
          items = filter(items, query, key: 'queryString')
          @appendItems(items)
        , (failure) =>
          span.detach()
          console.log("FAIL!", failure)
          throw failure

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
