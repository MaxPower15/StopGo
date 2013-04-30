# Use this method to generate a function that can be used 
# to queue and gate/ungate functions on ready.
#
# Create a ready function:
#     
#     myObject.ready = new StopGo(myObject);
#
# Queue a function:
#
#     myObject.ready(myFunction);
#
# When ready is true, queued functions will run immediately.
#
#     myObject.ready(true);
#
# When ready is false, any new functions will be queued.
#
#     myObject.ready(false);
#
# You can send additional arguments to the queued functions:
#
#     myObject.ready(function(name) { console.log("Hi, " + name + "!"); });
#     myObject.ready(true, "Max");
#
# Remove a function from the queue:
#
#     myObject.ready.remove(myFunction);
# 
# Get the queue:
#
#     myObject.ready.getQueue();
#
# Set the queue, it's just an array of functions:
#     
#     myObject.ready.setQueue(newQueue);
#

class StopGo


  constructor: ->
    @_queue = []
    @_green = false
    @_lock = false
    @allInOne = => @_allInOne arguments...
    @defineMethodsOn @allInOne
    return @allInOne
  

  # Utility method to define all this class's methods on an 
  # arbitrary obj, while maintaining the proper execution scope.
  defineMethodsOn: (obj) ->
    getType = {}
    for k, v of this
      ((k, v, klass) =>
        if getType.toString.call(v) is '[object Function]'
          obj[k] = -> klass[k].apply(klass, arguments)
      )(k, v, this)


  # Try to execute all the functions in the queue.
  flush: (args...) ->
    return this unless @_green
    @_lock = true
    for i in [0...@_queue.length]
      if fn = @_queue[i]
        if args.length or !@goArgs
          fn args...
        else
          fn @goArgs...
        @_queue[i] = null
      break unless @_green
    @filter (fn) -> fn?
    @_lock = false
    this


  # Filter the queue with the given condition function.
  filter: (cond) ->
    @_queue = (fn for fn in @_queue when cond(fn))
    this


  # Execute a single callback.
  # Push a callback onto the queue.
  push: (fn) ->
    @_queue.push(fn)
    this


  # Let the functions in now!
  go: (args...) ->
    @_green = true
    @goArgs = args
    @flush(args...)
    this


  # Stop any more functions from running.
  stop: ->
    @_green = false
    this


  # Let us accept any number of functions to queue.
  run: (fns...) ->
    @runFn(fn) for fn in fns
    this


  # Given a function, there are three possible scenarios.
  #
  # 1. Push to the end of the queue.
  # 2. Push to the end of the queue and immediately flush.
  # 3. Ignore the queue and execute immediately.
  runFn: (fn) ->
    if @_green
      # `@_lock` can be true if `fn` is _called by_ a 
      # function that is being flushed. In that case, we 
      # just want to execute immediately.
      if @_lock
        fn()
      else
        @push(fn)
        @flush()
    else
      @push(fn)
    this


  # Remove a bunch of functions.
  remove: (fns...) ->
    @removeFn(fn) for fn in fns
    this


  # Remove the given function from the queue.
  removeFn: (targetFn) ->
    @filter (fn) -> targetFn isnt fn
    this


  # Set the queue manually. It's just an array of functions.
  setQueue: (newQueue) ->
    @_queue = newQueue
    this


  # Get the queue. Maybe you want to reverse it or something.
  getQueue: -> @_queue


  # This is the preferred public interface. That is, it's what
  # runs when you call the constructor's return value as a function.
  _allInOne: (arg, rest...) ->
    return @go(rest...) if arg is true
    return @stop() if arg is false
    if arg?
      if arg instanceof Array
        @run arg...
      else
        @run arguments...
    else
      @_green


# `StopGo.when` lets us flatten a bunch of individual stopGos into 
# a single method. It builds a function that looks like:
#
#     -> stopGo1 -> stopGo2 -> stopGo3 -> fn()
#
# Then calls that function to set everything up.
StopGo.when = (stopGos...) ->
  result = new StopGo()
  lastFn = -> result.go(arguments...)
  for stopGo in stopGos.reverse()
    ((theFn, stopGo) ->
      lastFn = ->
        stopGo -> theFn(arguments...)
    )(lastFn, stopGo)
  lastFn()
  result


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
