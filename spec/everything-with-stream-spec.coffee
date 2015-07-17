class TestProvider
  name: "tst-provider"

  Stream = null

  shouldRun: -> true
  onStart: (evry) -> Stream = evry.Stream
  onQuery: (query) ->
    stream = new Stream (stream)
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
  workspace = everything = provider = null

  beforeEach ->
    jasmine.unspy(window, 'setTimeout') # Stupid ATOM...
    jasmine.Clock.useMock()
    spyOn(window, 'setTimeout').andCallFake (fn, milis) ->
      if milis
        jasmine.Clock.installed.setTimeout(fn, milis)
      else
        fn()

    workspace = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspace)
    EverythingView = require '../lib/everything-view'
    setTimeout =>
      console.log "Timed Out!"

    everything = new EverythingView()
    provider = new TestProvider()
    everything.registerProvider(provider)

  it "shows the items on screen", ->
    everything.show()
    setText "b"
    assertSelected "Foo"

  fit "makes every element appear little by little", ->
    selectedElement = -> workspace.querySelector('li.two-lines.selected div')
    loading = -> everything.loadingProviderElement('tst-provider').length > 0
    everything.show()
    window.e = everything

    expect(selectedElement()).toBeFalsey
    expect(loading()).toBe(true)

    jasmine.Clock.tick(201)
    expect(selectedElement().innerText).toEqual "Bar"
    console.log everything.loadingProviderElement()
    expect(loading()).toBe(true)

    jasmine.Clock.tick(101)
    expect(selectedElement().innerText).toEqual "Foo"
    expect(loading()).toBe(true)

    jasmine.Clock.tick(101)
    expect(selectedElement().innerText).toEqual "Foo"
    expect(loading()).toBe(false)

  assertSelected = (text) ->
    waitsFor -> workspace.querySelector('.everything li.two-lines')
    runs ->
      expect workspace.querySelector('li.two-lines.selected div').innerText
      .toEqual text

  setText = (text) ->
    everything.filterEditorView.setText(text)
    everything.populateList()
