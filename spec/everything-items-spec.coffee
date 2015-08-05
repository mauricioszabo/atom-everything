EverythingView = require '../lib/everything-view'

describe "EverythingView's Items", ->
  workspace = everything = null

  beforeEach ->
    workspace = atom.views.getView(atom.workspace)
    jasmine.unspy(window, 'setTimeout') # Stupid ATOM...
    jasmine.attachToDOM(workspace)
    everything = new EverythingView()

  it "adds items in the correct score", ->
    i1 = createItem("A", 1)
    i2 = createItem("B", 2)
    everything.show()

    everything.addItem(i1)
    everything.addItem(i2)
    expect everything.filteredItems
    .toEqual [i2, i1]

  it "adds and score itens when running the provider", ->
    {score} = require 'fuzzaldrin'
    provider =
      name: 'test'
      shouldRun: -> true
      onQuery: -> new Promise (resolve) ->
        resolve [
          { displayName: "Foo", queryString: "Foo" },
          { displayName: "Foo2", queryString: "Foo2" },
          { displayName: "Bar", queryString: "Bar" }
        ]
    everything.registerProvider(provider)
    everything.show()
    # We should check this case - when a provider returns later.
    # everything.filterEditorView.setText("F")
    # everything.populateList()
    everything.filterEditorView.setText("Fo")
    everything.populateList()

    waitsFor -> everything.filteredItems.length > 0
    runs ->
      expect everything.filteredItems.map (e) -> e.displayName
      .toEqual ["Foo", "Foo2"]

      expect everything.filteredItems.map (e) -> e.score
      .toEqual [score("Foo", "Fo"), score("Foo2", "Fo")]

  fit "registers a prefix to only trigger that provider", ->
    provider =
      name: 'test2'
      defaultPrefix: 'tst'
      shouldRun: -> true
      onQuery: -> new Promise (resolve) ->
        resolve [ { displayName: "Foo", queryString: "Foo" } ]

    configs = {}
    spyOn(atom.config, 'set')
    spyOn(atom.config, 'get').andCallFake -> 'tst'
    everything = new EverythingView()
    everything.registerProvider(provider)
    everything.show()

    expect(atom.config.set)
    .toHaveBeenCalledWith('everything.test2ProviderTrigger', 'tst');

    everything.filterEditorView.setText("Fo")
    everything.populateList()
    waitsFor ->
      everything.loadingProviderElement('test2').length == 0
    runs ->
      expect workspace.querySelector('li.two-lines.selected div')
      .toBe(null)

      everything.filterEditorView.setText("tstFo")
      everything.populateList()

      waitsFor ->
        workspace.querySelector('li.two-lines.selected div')
      runs ->
        expect workspace.querySelector('li.two-lines.selected div').innerText
        .toEqual('Foo')

  createItem = (name, score) ->
    { displayName: name, score: score, queryString: name }
