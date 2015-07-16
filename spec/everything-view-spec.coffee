EverythingView = require '../lib/everything-view'

class TestProvider
  name: "tst-provider"

  result: null

  runTimes: 0

  shouldRun: (query) -> query.length > 1
  function: (query) -> new Promise (resolve) =>
    @runTimes += 1
    resolve [
      {
        displayName: "Foo"
        queryString: "str Foo"
        additionalInfo: "f1"
        function: => @result = 'foo selected'
      }, {
        displayName: "Bar"
        queryString: "str Bar"
        additionalInfo: "b1"
        function: => @result = 'bar selected'
      }
    ]

describe "EverythingView", ->
  workspace = everything = provider = null

  beforeEach ->
    workspace = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspace)
    everything = new EverythingView()
    provider = new TestProvider()
    everything.registerProvider(provider)
    jasmine.unspy(window, 'setTimeout') # Stupid ATOM...

  it "displays provider information", ->
    everything.show()
    setText 'bar'
    assertSelected("Bar")

  it "matches by query string, not by display", ->
    everything.show()
    window.e2 = everything
    setText 'strb'
    assertSelected "Bar"

  it "doesn't query if shouldRun is false", ->
    everything = new EverythingView()
    provider = new TestProvider()
    everything.registerProvider(provider)
    setText 'f'
    setText 'foo'
    expect provider.runTimes
    .toEqual 1

  xit "shows items without setting timeouts the first way it runs", ->
    provider.shouldRun = -> true
    provider.function = -> new Promise (resolve) ->
      resolve [displayName: "Foo", score: 1, queryString: 'Foo']

    everything.show()
    expect workspace.querySelector('li.two-lines.selected div').innerText
    .toEqual "Foo"

  assertSelected = (text) ->
    waitsFor -> workspace.querySelector('.everything li.two-lines')
    runs ->
      expect workspace.querySelector('li.two-lines.selected div').innerText
      .toEqual text

  setText = (text) ->
    everything.filterEditorView.setText(text)
    everything.populateList()
