{SelectListView} = require 'atom-space-pen-views'
{filter, match} = require 'fuzzaldrin'

class EverythingView extends SelectListView
  timeout: 0
  providers: {}
  lastQuery = ""

  initialize: ->
    super
    @addClass('overlay from-top everything')
    @pane = atom.workspace.addModalPanel(item: this, visible: false)
    @storeFocusedElement()
    # @on 'keydown', (evt) => console.log(evt)

  cancelled: ->
    p.onStop(this) for _, p of @providers when p.onStop
    @pane.hide()

  destroy: ->
    @cancel()
    @pane.destroy()

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
    @cancel()

  getFilterKey: -> "queryString"

  registerProvider: (provider) ->
    @providers[provider.name] = provider

  getFilterQuery: ->
    query = super
    return query if query == lastQuery
    lastQuery = query
    @updateResults(query)
    query

  updateResults: (query) ->
    @setItems([])
    for name, provider of @providers when provider.shouldRun(query)
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

  appendItems: (items) ->
    @setItems(items.concat(@items))

  show: ->
    p.onStart(this) for _, p of @providers when p.onStart
    @pane.show()
    @filterEditorView.setText(lastQuery)
    super
    @updateResults(lastQuery)
    @filterEditorView.model.selectAll()
    @focusFilterEditor()

module.exports = EverythingView
