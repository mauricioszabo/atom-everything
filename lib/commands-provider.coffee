module.exports = class
  name: "commands"

  function: (search) -> new Promise (resolve) ->
    view = atom.views.getView(atom.workspace.getActiveTextEditor())
    commands = for command in atom.commands.findCommands(target: view)
      do ->
        cmdName = command.name
        {
          displayName: command.displayName,
          function: ->
            console.log(cmdName)
            atom.workspaceView.trigger(cmdName)
        }
    resolve(commands)
