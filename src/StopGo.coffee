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
    while @_queue.length > 0
      # pop fn. it's important this happens before fn executes to prevent an
      # infinite loop if fn calls go() on this queue.
      fn = @_queue.shift()

      if args.length or !@goArgs
        fn args...
      else
        fn @goArgs...

      # If fn calls stop() on this queue, stop processing.
      break if @_block or !@_green
    @_lock = false

    this


  synchronize: (fns...) ->
    @synchronizeFn(fn) for fn in fns
    this


  # Allow a method that executes asynchronously to block queue execution
  # until it is done. The function is passed an argument, the "done"
  # function, which should be called when the async work is complete.
  #
  # @_block is set in addition to stop/go so that, if another function outside
  # the synchronize loop calls go(), we will still wait for the "done" function
  # to be called.
  synchronizeFn: (fn) ->
    wrapperFn = =>
      @_block = true
      @stop()
      fn =>
        @_block = false
        @go()
    @runFn(wrapperFn)
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
    if @_green and !@_block
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
      else if typeof arg is 'string'
        this[arg](rest...)
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
