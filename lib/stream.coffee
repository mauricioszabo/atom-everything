{Disposable} = require 'atom'

module.exports = class Stream
  constructor: ->
    @_internalArray = []
    @_listeners = new Set()
    @_closeListeners = new Set()
    @_closed = false

  onData: (fn) ->
    @_listeners.add(fn)
    @_internalArray.forEach fn
    new Disposable => @_listeners.delete(fn)

  onClose: (fn) ->
    @_closeListeners.add(fn)
    fn() if @_closed
    new Disposable => @_closeListeners.delete(fn)

  push: (element) ->
    return if @_closed
    @_internalArray.push(element)
    @_listeners.forEach (fn) -> fn(element)

  close: ->
    return if @_closed
    @_closed = true
    @_closeListeners.forEach (fn) -> fn()
