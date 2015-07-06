{SelectListView} = require 'atom-space-pen-views'
{filter, match} = require 'fuzzaldrin'

remote = require('remote')
Menu = remote.require('menu')
MenuItem = remote.require('menu-item')

class EverythingView extends SelectListView
  timeout: 0
  providers: {}
  lastQuery = ""

  initialize: ->
    super
    @addClass('overlay from-top everything')
    @pane = atom.workspace.addModalPanel(item: this, visible: false)
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
