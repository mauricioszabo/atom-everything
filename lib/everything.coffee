EverythingView = require './everything-view'

module.exports = Everything =
  activate: (state) ->
    atom.commands.add 'atom-workspace', 'everything:fuzzy-finder', => new EverythingView()
