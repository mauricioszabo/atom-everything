{SelectListView, $} = require 'atom-space-pen-views'
fuzzaldrin = require 'fuzzaldrin'

remote = require('remote')
Menu = remote.require('menu')
MenuItem = remote.require('menu-item')

indexOfArray = (array, fn) ->
  for e, i in array
    return i if fn(e)
  null

class EverythingView extends SelectListView
  timeout: 0
  providers: {}
  lastQuery = ""

  initialize: ->
    super
    @fuzzaldrin = fuzzaldrin
    @addClass('overlay from-top everything')
    @pane = atom.workspace.addModalPanel(item: this, visible: false)
    @filteredItems = []
    @shouldUpdate = true
    @setLoading() # We do our loading alone!

    @on 'keydown', (evt) =>
      if(evt.keyCode == 9) # TAB
        evt.preventDefault()
        item = @getSelectedItem()
        if item.commands
          menu = new Menu()
          for name, command of item.commands
            do =>
              cmd = command
              item = new MenuItem(
                label: name,
                click: =>
                  cmd()
                  @cancel()
              )
              menu.append(item)
          {top, left} = @find('li.selected').offset()
          menu.popup(remote.getCurrentWindow(), parseInt(left + 20), parseInt(top + 10))

  cancelled: ->
    p.onStop(this) for _, p of @providers when p.onStop
    @pane.hide()

  addItem: (item) ->
    return if item.score == 0
    index = indexOfArray(@filteredItems, (fitem) -> fitem.score < item.score)
    if index?
      @filteredItems.splice(index, 0, item)
      # itemView = @generateItem(item)
      # @list.find("li:nth-child(#{index + 1})").before(itemView)
    else
      @filteredItems.push(item)
      # @list.append(@generateItem(item))
    @scheduleUpdate()

  populateList: ->
    query = @getFilterQuery()
    @updateResults(query)

  scheduleUpdate: ->
    if @shouldUpdate
      @shouldUpdate = false
      setTimeout => @updateView()

  updateView: ->
    @shouldUpdate = true
    @list.empty()
    if @filteredItems.length
      @setError()

      for i in [0...Math.min(@filteredItems.length, @maxItems)]
        itemView = @generateItem(@filteredItems[i])
        @list.append(itemView)

      # For now, we select only the first item.
      # We should ignore this if user already selected another item.
      @selectItemView(@list.find('li:first'))
    else
      @setError(@getEmptyMessage(0, @filteredItems.length))

  generateItem: (item) ->
    itemView = $(@viewForItem(item))
    itemView.data('select-list-item', item)
    itemView

  destroy: ->
    @cancel()
    @pane.destroy()

  viewForItem: (item) ->
    matches = fuzzaldrin.match(item.queryString, lastQuery)
    index = item.queryString.toLowerCase().indexOf(item.displayName.toLowerCase())

    display = for char, i in item.displayName.split("")
      if index == -1 || matches.indexOf(i + index) == -1
        char
      else
        "<b>#{char}</b>"

    providerDiv = if atom.config.get('everything.showProvidersName')
      "<div class='key-binding pull-right'>#{item.providerName}</div>"
    else
      ""

    """<li class="two-lines #{item.providerName}">
      #{providerDiv}<div>#{display.join("") || "&nbsp;"}</div>
      <div class="add-info">#{item.additionalInfo || "&nbsp;"}</div></li>"""

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
    query

  updateResults: (query) ->
    @filteredItems = []
    @scheduleUpdate()
    for name, provider of @providers when provider.shouldRun(query)
      do =>
        span = @find("span[data-provider='#{name}']")
        if span.length == 0
          @append("<span class='key-binding' data-provider='#{name}'>#{name}</span>")

        result = provider.function(query)
        @treatPromise(result, query, name)

    null

  treatPromise: (result, query, providerName) ->
    span = @loadingProviderElement(providerName)
    result.then (items) =>
      span.detach()
      items.forEach (i) =>
        item = Object.create(i)
        item.providerName = providerName
        item.score ?= fuzzaldrin.score(item.queryString, query)
        @addItem(item)
    .catch (failure) =>
      span.detach()
      console.log("FAIL!", failure)
      throw failure

  loadingProviderElement: (name) -> @find("span[data-provider='#{name}']")

  show: ->
    @storeFocusedElement()
    p.onStart(this) for _, p of @providers when p.onStart
    @pane.show()
    @filterEditorView.setText(lastQuery)
    super
    @updateResults(lastQuery)
    @filterEditorView.model.selectAll()
    @focusFilterEditor()

module.exports = EverythingView
