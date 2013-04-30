describe "StopGo", ->

  it "can queue functions until go", ->
    stopGo = new StopGo()
    result = ""
    stopGo.run -> result += "a"
    stopGo.run -> result += "b"
    expect(result).toBe("")
    stopGo.go()
    expect(result).toBe("ab")

  it "can be nested multiple times in itself", ->
    stopGo = new StopGo()
    result = ""
    stopGo.run ->
      result += "a"
      stopGo.run ->
        result += "b"
        stopGo.run ->
          result += "c"
    expect(result).toBe("")
    stopGo.go()
    expect(result).toBe("abc")

  it "can be stopped from within a nested scope", ->
    stopGo = new StopGo()
    result = ""
    stopGo.run ->
      result += "a"
      stopGo.run ->
        result += "b"
        stopGo.stop()
        stopGo.run ->
          result += "c"
    expect(result).toBe("")
    stopGo.go()
    expect(result).toBe("ab")
    stopGo.go()
    expect(result).toBe("abc")

  it "gives full access to the queue", ->
    stopGo = new StopGo()
    fn1 = ->
    fn2 = ->
    stopGo.run(fn1).run(fn2)
    expect(stopGo.getQueue()[0]).toBe(fn1)
    expect(stopGo.getQueue()[1]).toBe(fn2)
    stopGo.setQueue(stopGo.getQueue().reverse())
    expect(stopGo.getQueue()[0]).toBe(fn2)
    expect(stopGo.getQueue()[1]).toBe(fn1)

  it "can remove a function from the queue", ->
    stopGo = new StopGo()
    fn1 = ->
    fn2 = ->
    stopGo.run(fn1).run(fn2)
    expect(stopGo.getQueue().length).toBe(2)
    stopGo.remove(fn1)
    expect(stopGo.getQueue().length).toBe(1)
    expect(stopGo.getQueue()[0]).toBe(fn2)

  it "can use the short-hand syntax to queue a function", ->
    stopGo = new StopGo()
    result = ""
    stopGo -> result += "a"
    stopGo -> result += "b"
    expect(result).toBe("")
    stopGo.go()
    expect(result).toBe("ab")

  it "can use short-hand syntax to trigger go", ->
    stopGo = new StopGo()
    result = ""
    stopGo -> result += "a"
    stopGo -> result += "b"
    expect(result).toBe("")
    stopGo(true)
    expect(result).toBe("ab")

  it "can use short-hand syntax to trigger stop", ->
    stopGo = new StopGo()
    result = ""
    stopGo -> result += "a"
    stopGo ->
      result += "b"
      stopGo(false)
      stopGo ->
        result += "c"
    expect(result).toBe("")
    stopGo(true)
    expect(result).toBe("ab")
    stopGo(true)
    expect(result).toBe("abc")

  it "can chain with multiple StopGo instances", ->
    sg1 = new StopGo()
    sg2 = new StopGo()

    result = ""
    sg1 ->
      result += "a"
      sg2 ->
        result += "b"

    expect(result).toBe("")
    sg1(true)
    expect(result).toBe("a")
    sg2(true)
    expect(result).toBe("ab")

  it "can chain with multiple StopGo instances, in reverse", ->
    sg1 = new StopGo()
    sg2 = new StopGo()

    result = ""
    sg1 ->
      result += "a"
      sg2 ->
        result += "b"

    expect(result).toBe("")
    sg2(true)
    expect(result).toBe("")
    sg1(true)
    expect(result).toBe("ab")

  it "can use StopGo.when to chain", ->
    sg1 = new StopGo()
    sg2 = new StopGo()

    result = ""
    StopGo.when sg1, sg2, -> result = "a"
    expect(result).toBe("")
    sg1(true)
    expect(result).toBe("")
    sg2(true)
    expect(result).toBe("a")
