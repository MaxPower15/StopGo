# The `StopGoPromise` class uses `StopGo` to implement the Promise API.
#
# I based the behavior on these descriptions of the Promise API:
#
# - https://gist.github.com/domenic/3889970
# - http://wiki.commonjs.org/wiki/Promises/A
#
# I did not implement the progress handler.
#
# Caveat: I'm not sure how the behavior of rejection forwarding is 
# supposed to work, or if it's supposed to happen at all. In this 
# implementation, if one promise is rejected, all the following promises 
# are also rejected with the same arguments.

class StopGoPromise


  # `@continued` can be another promise. Initializing with that means 
  # this promise should be dependent on `@continued`.
  constructor: (@continued) ->
    @finished = new StopGo()
    @_stopGos = []
    @after(@continued) if @continued


  # Make this promise dependent on `promise` finishing.
  after: (promise) ->
    promise.forwardReject(this)
    @_stopGos.push(promise.finished)
    this


  # On reject, forward to next promise. No need to wait for 
  # dependent promises to finish. If this failed, they all failed.
  forwardReject: (to) ->
    @finished (state, args...) ->
      to.reject(args...) if state is "rejected"
    this


  # Get an array of all the dependent StopGo instances.
  dependents: ->
    [].concat(@_stopGos).concat([@finished])


  # Execute fn when this and all dependent promises are finished.
  continue: (fn) ->
    StopGo.when(@dependents()...).run ->
      try
        fn(arguments...)
      catch e
        console?.log e.message
        console?.log e.stack
    this


  # If a promise is passed in, chain it and return.
  #
  # If functions are passed in, create a new promise that will be 
  # resolved or rejected with the return value of each function.
  then: (resolvedFn, rejectedFn) ->
    if resolvedFn instanceof StopGoPromise
      resolvedFn.after(this)
      newPromise = new StopGoPromise(resolvedFn)
      resolvedFn.then ->
        newPromise.resolve(arguments...)
      , ->
        newPromise.reject(arguments...)
      newPromise
    else
      newPromise = new StopGoPromise(this)
      @continue (state, args...) ->
        if state is "resolved"
          newPromise.resolve resolvedFn?(args...)
        else if state is "rejected"
          newPromise.reject rejectedFn?(args...)
        else
          throw new Error("Invalid finished state, '#{state}'. No callbacks ran.")
      newPromise


  # Finish this promise in a resolved state, after dependent states are done.
  resolve: (args...) ->
    StopGo.when(@_stopGos...).run => @finished.go "resolved", args...
    this


  # Finish this promise in a rejected state immediately.
  reject: (args...) ->
    @finished.go "rejected", args...
    this


# Chain promises with a single function.
StopGoPromise.when = (promises...) ->
  result = new StopGoPromise().resolve()
  lastPromise = null
  for promise in promises
    promise.after(lastPromise) if lastPromise
    lastPromise = promise
  result.after(lastPromise)
  result
