EverythingView = require '../lib/everything-view'

describe "EverythingView's Items", ->
  workspace = everything = null

  beforeEach ->
    workspace = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspace)
    everything = new EverythingView()

  fit "adds items in the correct score", ->
    i1 = createItem("A", 1)
    i2 = createItem("B", 2)
    everything.show()

    everything.addItem(i1)
    everything.addItem(i2)
    expect everything.filteredItems
    .toEqual [i2, i1]

    waitsFor -> workspace.querySelector('.everything li.two-lines')
    runs ->
      expect workspace.querySelector('li.two-lines.selected div').innerText
      .toEqual "B"

  createItem = (name, score) ->
    { displayName: name, score: score, queryString: name }
