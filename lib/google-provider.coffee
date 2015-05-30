http = require 'http'
child = require 'child_process'

module.exports = class
  name: "google"

  timeout = 0

  getJSON = (url) -> new Promise (resolve) ->
    content = ""
    http.get url, (res) ->
      res.setEncoding("utf8")
      res.on "data", (chunk) -> content += chunk
      res.on "end", -> resolve JSON.parse(content)

  function: (query) -> new Promise (resolve) ->
    clearTimeout timeout
    timeout = setTimeout ->
      getJSON "http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q=#{query.substring(1)}"
      .then (result) ->
        items = result.responseData.results.map (result) ->
          {
            displayName: result.titleNoFormatting,
            queryString: "?#{result.titleNoFormatting}",
            additionalInfo: result.url,
            function: ->
              child.spawnSync('google-chrome', ['--no-sandbox', result.url])
          }
        resolve(items)
    , 500
      # items = json.responseData.results.map (data) =>
      #   data.titleNoFormatting
      # console.log(items)
        # {
        #   displayName: command.displayName,
        #   queryString: command.displayName,
        #   function: ->
        #     atom.workspaceView.trigger(cmdName)
        #   additionalInfo: addInfo
        # }

  shouldRun: (query) -> query[0] == '?' && query.length > 4
