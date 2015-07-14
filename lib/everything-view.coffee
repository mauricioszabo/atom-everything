{SelectListView, $} = require 'atom-space-pen-views'
{filter, match, score} = require 'fuzzaldrin'

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
    @addClass('overlay from-top everything')
    @pane = atom.workspace.addModalPanel(item: this, visible: false)
    @filteredItems = []

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
    index = indexOfArray(@filteredItems, ({score}) -> score < item.score)
    if index?
      @filteredItems.splice(index, 0, item)
      itemView = @generateItem(item)
      @list.find("li:nth-child(#{index + 1})").before(itemView)
    else
      @filteredItems.push(item)
      @list.append(@generateItem(item))
    # For now, we select only the first item.
    # We should ignore this if user already selected another item.
    @selectItemView(@list.find('li:first'))


  populateList: ->
    return unless @filteredItems?
    @list.empty()
    if @filteredItems.length
      @setError(null)

      for i in [0...Math.min(@filteredItems.length, @maxItems)]
        itemView = @generateItem(@filteredItems[i])
        @list.append(itemView)

      @selectItemView(@list.find('li:first'))
    else
      @setError(@getEmptyMessage(@items.length, @filteredItems.length))

  generateItem: (item) ->
    itemView = $(@viewForItem(item))
    itemView.data('select-list-item', item)
    itemView

  destroy: ->
    @cancel()
    @pane.destroy()

  viewForItem: (item) ->
    matches = match(item.queryString, lastQuery)
    index = item.queryString.toLowerCase().indexOf(item.displayName.toLowerCase())

    display = for char, i in item.displayName.split("")
      if index == -1 || matches.indexOf(i + index) == -1
        char
      else
        "<b>#{char}</b>"

    """<li class="two-lines">
      <div>#{display.join("") || "&nbsp;"}</div>
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
        .catch (failure) =>
          span.detach()
          console.log("FAIL!", failure)
          throw failure

    null

  appendItems: (items) ->
    @setItems(items.concat(@items))

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
