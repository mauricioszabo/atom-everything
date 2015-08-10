class TestProvider
  name: "tst-provider"

  Stream = null

  shouldRun: -> true
  onStart: (evry) -> Stream = evry.Stream
  onQuery: (query) ->
    stream = new Stream()
    stream.id = Math.random()
    setTimeout =>
      stream.push(
        displayName: "Foo"
        queryString: "str Foo"
        score: 2
      )
    , 300

    setTimeout =>
      stream.push(
        displayName: "Bar"
        queryString: "str Bar"
        score: 1
      )
    , 200

    setTimeout (=> stream.close()), 400
    stream

describe "EverythingView using Stream API", ->
  workspace = null

  beforeEach ->
    spyOn(atom.config, 'set')

  createEverything = ->
    jasmine.unspy(window, 'setTimeout') # Stupid ATOM...

    workspace = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspace)
    EverythingView = require '../lib/everything-view'

    evry = new EverythingView()
    provider = new TestProvider()
    evry.registerProvider(provider)
    evry

  it "makes every element appear little by little", ->
    evry = createEverything()
    evry.show()

    expect(selectedElement()).toBeFalsey
    expect(loading(evry)).toBe(true)

    waitsFor -> selectedElement()
    runs ->
      expect(selectedElement().innerText).toEqual "Bar"
      expect(loading(evry)).toBe(true)

    waitsFor -> selectedElement().innerText == "Foo"
    runs ->
      expect(selectedElement().innerText).toEqual "Foo"
      expect(loading(evry)).toBe(true)

    waitsFor -> !loading(evry)
    runs ->
      expect(selectedElement().innerText).toEqual "Foo"
      expect(loading(evry)).toBe(false)

  it "disposes old streams when typing new text", ->
    evry = createEverything(true)
    evry.show()
    setText evry, "foo"

    waitsFor ->
      selectedElement() && selectedElement().innerText == 'Foo'
    runs ->
      expect(evry.filteredItems.length).toEqual(2)

      setText evry, "bar"
      waitsFor -> !selectedElement()
      runs ->
        expect(evry.filteredItems).toEqual([])

        waitsFor ->
          selectedElement() && selectedElement().innerText == 'Foo'
        runs ->
          expect(evry.filteredItems.length).toEqual(2)

  selectedElement = -> workspace.querySelector('li.two-lines.selected div')
  loading = (e) -> e.loadingProviderElement('tst-provider').length > 0

  setText = (e, text) ->
    e.filterEditorView.setText(text)
    e.populateList()
