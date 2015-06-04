evry = null

module.exports = class
  name: "commands"

  onStart: (finder) ->
    evry = finder

  function: (search) -> new Promise (resolve) ->
    view = atom.views.getView(atom.workspace.getActiveTextEditor())
    bindings = atom.keymaps.findKeyBindings(target: @eventElement)

    commands = for command in atom.commands.findCommands(target: view)
      do ->
        addInfo = for b in bindings when b.command == command.name
          b.keystrokes

        cmdName = command.name
        {
          function: ->
            event = new CustomEvent(cmdName, {bubbles: true, cancelable: true})
            workspace = evry.previouslyFocusedElement[0]
            workspace.dispatchEvent(event)
          commands: {
            "Copy command to clipboard": -> atom.clipboard.write cmdName
          }
          additionalInfo: addInfo
          displayName: command.displayName
          queryString: command.displayName
        }
    resolve(commands)
