describe "StopGoPromise", ->


  it "runs the success function when resolved", ->
    promise = new StopGoPromise()
    result = ""
    promise.then (-> result = "a"), (-> result = "b")
    expect(result).toBe("")
    promise.resolve()
    expect(result).toBe("a")


  it "runs the error function when rejected", ->
    promise = new StopGoPromise()
    result = ""
    promise.then (-> result = "a"), (-> result = "b")
    expect(result).toBe("")
    promise.reject()
    expect(result).toBe("b")


  it "StopGoPromise.when creates a new promise", ->
    p1 = new StopGoPromise()
    p2 = StopGoPromise.when(p1)
    expect(p2 instanceof StopGoPromise)
    expect(p1 isnt p2)


  it "can chain with StopGoPromise.when", ->
    p1 = new StopGoPromise()
    p2 = new StopGoPromise()
    result = ""
    StopGoPromise.when(p1, p2).then (-> result = "a"), (-> result = "b")
    expect(result).toBe("")
    p1.resolve()
    expect(result).toBe("")
    p2.resolve()
    expect(result).toBe("a")


  it "forwards rejection through the chain", ->
    p1 = new StopGoPromise()
    p2 = new StopGoPromise()
    result = ""
    StopGoPromise.when(p1, p2).then (-> result = "a"), (-> result = "b")
    expect(result).toBe("")
    p1.reject()
    expect(result).toBe("b")


  it "forwards rejection through the chain (reject the other component)", ->
    p1 = new StopGoPromise()
    p2 = new StopGoPromise()
    result = ""
    StopGoPromise.when(p1, p2).then (-> result = "a"), (-> result = "b")
    expect(result).toBe("")
    p2.reject()
    expect(result).toBe("b")


  it "preserves order of operations when being chained", ->
    p1 = new StopGoPromise()
    p2 = new StopGoPromise()

    result = ""
    p1.then -> result += "a"
    p1.then -> result += "b"
    p2.then -> result += "c"
    p2.then -> result += "d"

    p1.then(-> result += "e").then(p2)

    expect(result).toBe("")
    p1.resolve()
    expect(result).toBe("abe")
    p2.resolve()
    expect(result).toBe("abecd")
      

  it "forwards arguments through promises via return values", ->
    p1 = new StopGoPromise()
    p2 = new StopGoPromise()
    result = ""
    p1
    .then(p2)
    .then (arg) ->
      expect(arg).toBe("a")
      arg + "b"
    .then (arg) ->
      expect(arg).toBe("ab")
      result = arg + "c"
    , (arg) ->
      result = arg
    expect(result).toBe("")
    p1.resolve()
    expect(result).toBe("")
    p2.resolve("a")
    expect(result).toBe("abc")


  it "forwards rejection when chained with then", ->
    p1 = new StopGoPromise()
    p2 = new StopGoPromise()
    result = ""
    p1
    .then(p2)
    .then (arg) ->
      expect(arg).toBe("a")
      arg + "b"
    .then (arg) ->
      expect(arg).toBe("ab")
      result = arg + "c"
    , (arg) ->
      result = "error: #{arg}"
    
    p1.reject("testing")
    expect(result).toBe("error: testing")
