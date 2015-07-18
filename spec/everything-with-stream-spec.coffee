class TestProvider
  name: "tst-provider"

  Stream = null

  shouldRun: -> true
  onStart: (evry) -> Stream = evry.Stream
  onQuery: (query) ->
    console.log 'onQuery'
    stream = new Stream()
    stream.id = Math.random()
    console.log "Stream:", stream
    setTimeout =>
      console.log "sending FOO"
      stream.push(
        displayName: "Foo"
        queryString: "str Foo"
        score: 2
      )
    , 3000

    setTimeout =>
      console.log "sending BAR"
      stream.push(
        displayName: "Bar"
        queryString: "str Bar"
        score: 1
      )
    , 2000

    setTimeout (=> stream.close()), 4000
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

  it "makes every element appear little by little", ->
    console.log "Teste1"
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

  it "disposes old streams when typing new text", ->
    console.log "Teste2"
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
