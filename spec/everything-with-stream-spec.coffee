class TestProvider
  name: "tst-provider"

  Stream = null

  shouldRun: -> true
  onStart: (evry) -> Stream = evry.Stream
  onQuery: (query) ->
    stream = new Stream()
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

  createEverything = ->
    jasmine.unspy(window, 'setTimeout') # Stupid ATOM...
    # jasmine.Clock.useMock()
    # spyOn(window, 'setTimeout').andCallFake (fn, milis) ->
    #   if milis
    #     jasmine.Clock.installed.setTimeout(fn, milis)
    #   else
    #     fn()

    workspace = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspace)
    EverythingView = require '../lib/everything-view'

    everything = new EverythingView()
    provider = new TestProvider()
    everything.registerProvider(provider)
    everything

  fit "makes every element appear little by little", ->
    everything = createEverything()
    everything.show()

    console.log "Starting..."
    expect(selectedElement()).toBeFalsey
    expect(loading(everything)).toBe(true)

    waitsFor -> selectedElement()
    runs ->
      expect(selectedElement().innerText).toEqual "Bar"
      expect(loading(everything)).toBe(true)

    waitsFor -> selectedElement().innerText == "Foo"
    runs ->
      expect(selectedElement().innerText).toEqual "Foo"
      expect(loading(everything)).toBe(true)

    waitsFor -> !loading(everything)
    runs ->
      expect(selectedElement().innerText).toEqual "Foo"
      expect(loading(everything)).toBe(false)

  fit "disposes old streams when typing new text", ->
    everything = createEverything()
    everything.show()
    setText everything, "foo"

    waitsFor -> selectedElement() && selectedElement().innerText == 'Foo'
    runs ->
      expect(everything.filteredItems.length).toEqual(2)

      setText everything, "bar"
      waitsFor -> !selectedElement()
      runs ->
        expect(everything.filteredItems).toEqual([])

        waitsFor ->
          selectedElement() && selectedElement().innerText == 'Foo'
        runs ->
          expect(everything.filteredItems.length).toEqual(2)

  selectedElement = -> workspace.querySelector('li.two-lines.selected div')
  loading = (e) -> e.loadingProviderElement('tst-provider').length > 0

  setText = (e, text) ->
    e.filterEditorView.setText(text)
    e.populateList()
