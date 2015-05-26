module.exports = class
  name: "commands"

  function: (search) -> new Promise (resolve) ->
    view = atom.views.getView(atom.workspace.getActiveTextEditor())
    bindings = atom.keymaps.findKeyBindings(target: @eventElement)

    commands = for command in atom.commands.findCommands(target: view)
      do ->
        addInfo = for b in bindings when b.command == command.name
          b.keystrokes

        cmdName = command.name
        {
          displayName: command.displayName,
          queryString: command.displayName,
          function: ->
            atom.workspaceView.trigger(cmdName)
          additionalInfo: addInfo
        }
    resolve(commands)
