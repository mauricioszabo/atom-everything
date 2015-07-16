Stream = require '../lib/stream'

stream = null

describe "Stream", ->
  beforeEach ->
    stream = new Stream()

  it "listens to stream events", ->
    data = []
    stream.onData (e) -> data.push(e)
    stream.push("Foo")
    stream.push("Bar")

    expect(data).toEqual(["Foo", "Bar"])

  it "calls for every element already added", ->
    data = []
    stream.push("Foo")
    stream.push("Bar")
    stream.onData (e) -> data.push(e)

    expect(data).toEqual(["Foo", "Bar"])

  it "allows to close the stream", ->
    closed = false
    stream.onClose -> closed = true
    stream.close()
    expect(closed).toBe true

  it "allows to close the stream even when it is listened later", ->
    data = []
    stream.push("Foo")
    stream.onData (e) -> data.push(e)
    stream.push("Bar")
    stream.close()
    stream.onClose -> data.push("Closed!")
    stream.close()
    stream.push("Baz")
    expect(data).toEqual(["Foo", "Bar", "Closed!"])

  xit "sends the data, and close, in order", ->
    # This needs to be implemented, somehow
    data1 = []
    data2 = []

    stream.onClose -> data1.push("Closed!")
    stream.onData (e) -> data1.push(e)
    stream.push("Foo")
    stream.push("Bar")
    stream.close()

    stream.onClose -> data2.push("Closed!")
    stream.onData (e) -> data2.push(e)

    expect(data1).toEqual(["Foo", "Bar", "Closed!"])
    expect(data2).toEqual(["Foo", "Bar", "Closed!"])

  it "can dispose the listen of item", ->
    data = []
    disposable = stream.onData (e) -> data.push(e)
    stream.push("Foo")
    disposable.dispose()
    stream.push("Bar")
    expect(data).toEqual(["Foo"])
    window.S = Stream
