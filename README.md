# Everything

This package tries to substitute Command Palette and others.

Mostly, this is a package to register various kinds of "finders", and then Everything will try to fit then all in a single list.

![A screenshot of your package](https://raw.githubusercontent.com/mauricioszabo/atom-everything/master/docs/preview.gif)

## Why use it?

I began to work with atom but I needed to remember lots of different keystrokes: one from Symbols, one for Project Symbols, one for Files and one for Commands.

When I began to work on my Rails-I18n project, things only became worse: now I had to remember one for find-keys and one for find-translations. This would not scale.

With Everything, we create "providers". By default, there is only "commands" and "google" profiler. You can, too, define when each profiler will run - Google will run only if we began to query with "?".

Most of all, Everything permits us to find and show different things. In Rails-I18n package, we can query by key or by translation, and Everything will happily find both. It will display the translation and the I18n key in different places, too. Even better, the finding process is asynchronous: we Everything will show (as in the screenshot) that it is still waiting for some provider's answer.

In the future, we'll be able to bind multiple actions (for instance, we could bind the "google" provider with "open in browser" as the default, and "copy URL to clipboard" as a secondary action).
