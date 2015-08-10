EverythingView = require '../lib/everything-view'

test2Provider =
  name: 'test2'
  defaultPrefix: 'tst'
  shouldRun: -> true
  onQuery: -> new Promise (resolve) ->
    resolve [ { displayName: "Foo", queryString: "Foo" } ]

describe "EverythingView's Items", ->
  workspace = everything = null

  beforeEach ->
    workspace = atom.views.getView(atom.workspace)
    jasmine.unspy(window, 'setTimeout') # Stupid ATOM...
    jasmine.attachToDOM(workspace)
    everything = new EverythingView()
    spyOn(atom.config, 'set')

  it "registers a prefix to only trigger that provider", ->
    configs = {}
    everything.registerProvider(test2Provider)
    expect(atom.config.set)
    .toHaveBeenCalledWith('everything.test2ProviderTrigger', 'tst')

  it "only calls this provider if trigger is present", ->
    spyOn(atom.config, 'get').andCallFake ->
      { test2ProviderTrigger: "tst" }

    everything.registerProvider(test2Provider)
    everything.show()
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
        window.e = everything
        workspace.querySelector('li.two-lines.selected div')
      runs ->
        expect workspace.querySelector('li.two-lines.selected div:nth-child(2)').innerText
        .toEqual('Foo')
