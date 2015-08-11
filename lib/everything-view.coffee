{SelectListView, $} = require 'atom-space-pen-views'
{CompositeDisposable} = require 'atom'

remote = require('remote')
Menu = remote.require('menu')
fuzzaldrin = require 'fuzzaldrin'
MenuItem = remote.require('menu-item')

indexOfArray = (array, fn) ->
  for e, i in array
    return i if fn(e)
  null

module.exports = class EverythingView extends SelectListView
  lastQuery = ""
  fuzzaldrin: fuzzaldrin
  shouldUpdate: true
  Stream: require('./stream')

  initialize: ->
    super
    @visible = false
    @providers = {}
    @prefixes = []
    @providersByPrefix = {}
    @filteredItems = []
    @addClass('overlay from-top everything')
    @pane = atom.workspace.addModalPanel(item: this, visible: false)
    @setLoading() # We do our loading alone!
    @append "<div id='providers'>"
    @streams = new CompositeDisposable()
    setTimeout (=> @cleanOldTriggers()), 1000

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
    @streams.dispose()
    p.onStop(this) for _, p of @providers when p.onStop
    @pane.hide()
    @visible = false

  cleanOldTriggers: ->
    config = atom.config.get('everything') || {}
    providersName = new Set(for name, _ of @providers
      "#{name}ProviderTrigger"
    )
    for key, _ of config when key.match(/Trigger$/)
      if !providersName.has(key)
        atom.config.unset("everything.#{key}")

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
    @filteredItems.pop() if @filteredItems.length > @maxItems
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

  getFilterQuery: ->
    query = super
    return query if query == lastQuery
    lastQuery = query
    query

  updateResults: (query) ->
    @streams.dispose()
    @filteredItems = []
    @streams = new CompositeDisposable()
    @scheduleUpdate()

    @eachProviderTriggered query, (name, provider, query) =>
      span = @find("span[data-provider='#{name}']")
      if span.length == 0
        $('div#providers').append("<span class='key-binding'
          data-provider='#{name}'>#{name}</span>")

      result = provider.onQuery(query)
      if result.then # It's a promise, probably
        @treatPromise(result, query, name)
      else # It's probaby a stream
        @treatStream(result, query, name)

  eachProviderTriggered: (query, fn) ->
    triggers = []
    triggerMapping = {}
    config = atom.config.get('everything') || {}
    for name, provider of @providers
      trigger = config["#{name}ProviderTrigger"]
      trigger ?= ''
      triggers.push(trigger)
      triggerMapping[trigger] ?= []
      triggerMapping[trigger].push(@providers[name])

    txt = triggers.sort( (e, f) -> e.length < f.length ).join("|")
    regexp = new RegExp(txt)

    trigger = query.match(regexp)
    providers = if trigger
      query = query.replace(trigger[0], '')
      triggerMapping[trigger[0]] || []
    else
      providers = triggerMapping[''] || []

    for provider in providers when provider.shouldRun(query)
      fn(provider.name, provider, query.trim())
      null #Please, don't create lots of arrays!

  treatPromise: (result, query, providerName) ->
    span = @loadingProviderElement(providerName)
    result.then (items) =>
      span.detach()
      items.forEach (item) => @scoreItem(item, query, providerName)
    .catch (failure) =>
      span.detach()
      atom.notifications.addError("Uncaught error on provider #{providerName}",
        detail: "Message: #{failure.message}\n#{failure.stack}")

  treatStream: (result, query, providerName) ->
    span = @loadingProviderElement(providerName)
    @streams.add result.onData (item) =>
      @scoreItem(item, query, providerName)
    @streams.add result.onClose => span.detach()

  scoreItem: (i, query, name) ->
    item = Object.create(i)
    item.providerName = name
    item.score ?= fuzzaldrin.score(item.queryString, query)
    @addItem(item)

  loadingProviderElement: (name) -> @find("span[data-provider='#{name}']")

  show: ->
    @storeFocusedElement()
    p.onStart(this) for _, p of @providers when p.onStart
    @pane.show()
    @visible = true
    @filterEditorView.setText(lastQuery)
    super

    $('div#providers').html('')
    @updateResults(lastQuery)
    @filterEditorView.model.selectAll()
    @focusFilterEditor()

  registerProvider: (provider) ->
    # Sets a config for provider prefix
    config = atom.config.get('everything') || {}
    key = "#{provider.name}ProviderTrigger"
    if !config[key]
      provider.defaultPrefix ?= ""
      atom.config.set("everything.#{key}", provider.defaultPrefix)
    # Adds into provider list
    @providers[provider.name] = provider
    provider.onStart(this) if @visible && provider.onStart
