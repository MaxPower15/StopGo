# The `StopGoPromise` class uses `StopGo` to implement the Promise API.
class StopGoPromise


  constructor: (@continued) ->
    @finished = new StopGo()
    @_stopGos = []
    @after(@continued) if @continued


  after: (promise) ->
    promise.forwardReject(this)
    @_stopGos.push(promise.finished)
    this


  forwardReject: (to) ->
    @finished (state, args...) ->
      to.reject(args...) if state is "rejected"
    this


  # Execute `fn` when both `@continued` and `@finished` are in a
  # completion state.
  continue: (fn) ->
    StopGo.when([].concat(@_stopGos).concat([@finished])...).run ->
      try
        fn(arguments...)
      catch e
        console?.log e.message
        console?.log e.stack
    this


  then: (resolvedFn, rejectedFn) ->
    @continue (state, args...) ->
      if state is "resolved"
        resolvedFn?(args...)
      else if state is "rejected"
        rejectedFn?(args...)
      else
        throw new Error("Invalid finished state, '#{state}'. No callbacks ran.")
    new StopGoPromise(this)


  resolve: (args...) ->
    StopGo.when(@_stopGos...).run => @finished.go "resolved", args...
    this


  reject: (args...) ->
    @finished.go "rejected", args...
    this


StopGoPromise.when = (promises...) ->
  result = new StopGoPromise().resolve()
  lastPromise = null
  for promise in promises
    promise.after(lastPromise) if lastPromise
    lastPromise = promise
  result.after(lastPromise)
  result

