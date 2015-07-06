eventElement = null
commands = []

module.exports = class
  name: "commands"

  onStart: (finder) ->
    prev = finder.previouslyFocusedElement[0]
    if prev and prev isnt document.body
      eventElement = prev
    else
      eventElement = atom.views.getView(atom.workspace)

    bindings = atom.keymaps.findKeyBindings(target: eventElement)
    commands = atom.commands.findCommands(target: eventElement).map (command) ->
      addInfo = for b in bindings when b.command == command.name
        b.keystrokes
      addTags = addInfo.map (e) => "<div class='key-binding'>#{e}</div>"

      cmdName = command.name
      {
        function: ->
          event = new CustomEvent(cmdName, {bubbles: true, cancelable: true})
          workspace = eventElement
          workspace.dispatchEvent(event)
        commands: {
          "Copy command to clipboard": -> atom.clipboard.write cmdName
        }
        additionalInfo: addTags.join(" ")
        displayName: command.displayName
        queryString: command.displayName
      }

  function: (search) -> new Promise (resolve) ->
    view = atom.views.getView(atom.workspace.getActiveTextEditor())
    resolve(commands)
