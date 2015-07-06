EverythingView = require '../lib/everything-view'

class TestProvider
  name: "tst-provider"

  result: null

  shouldRun: -> true
  function: (query) -> new Promise (resolve) =>
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

  it "displays provider information", ->
    everything.show()
    setText 'bar'
    assertSelected("Bar")

  it "matches by query string, not by display", ->
    everything.show()
    setText 'strb'
    assertSelected "Bar"


  assertSelected = (text) ->
    waitsFor -> workspace.querySelector('.everything li.two-lines')
    runs ->
      expect workspace.querySelector('li.two-lines.selected div').innerText
      .toEqual text

  setText = (text) ->
    everything.filterEditorView.setText(text)
    everything.getFilterQuery()
