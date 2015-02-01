describe "StopGo", ->
  describe 'when multiple functions are queued sequentially', ->
    it 'queues them, then executes them in sequential order on go()', ->
      stopGo = new StopGo()
      result = ""
      stopGo.run -> result += "a"
      stopGo.run -> result += "b"
      expect(result).toBe("")
      stopGo.go()
      expect(result).toBe("ab")


  describe 'when functions that are being flushed queue other functions on the same StopGo', ->
    it 'executes them in natural execution order', ->
      stopGo = new StopGo()
      result = ''
      stopGo.run ->
        result += 'a'
        stopGo.run ->
          result += 'b'
          stopGo.run ->
            result += 'c'
      expect(result).toBe('')
      stopGo.go()
      expect(result).toBe('abc')


  describe 'when one function that\'s being flushed stops the queue', ->
    it 'finishes executing that function, but halts before flushing the rest of the queue', ->
      stopGo = new StopGo()
      result = ""
      stopGo.run ->
        result += "a"
        stopGo.run ->
          stopGo.stop()
          result += "b"
          stopGo.run ->
            result += "c"
      expect(result).toBe("")
      stopGo.go()
      expect(result).toBe("ab")
      stopGo.go()
      expect(result).toBe("abc")


  describe 'getQueue', ->
    it 'returns all queued functions, in the order that they were queued', ->
      stopGo = new StopGo()
      fn1 = ->
      fn2 = ->
      stopGo.run(fn1).run(fn2)
      expect(stopGo.getQueue()[0]).toBe(fn1)
      expect(stopGo.getQueue()[1]).toBe(fn2)
      stopGo.setQueue(stopGo.getQueue().reverse())
      expect(stopGo.getQueue()[0]).toBe(fn2)
      expect(stopGo.getQueue()[1]).toBe(fn1)


  describe 'synchronize', ->
    it 'blocks queue execution until done() is called', ->
      sg = new StopGo()
      synchronizing = false
      sg.synchronize (done) ->
        synchronizing = true
        setTimeout(done, 10)
      ran = false
      sg -> ran = true
      sg(true)
      expect(synchronizing).toBe(true)
      expect(ran).toBe(false)
      waitsFor (-> ran), 50


  describe 'remove', ->
    it 'removes the given function from the queue', ->
      stopGo = new StopGo()
      fn1 = ->
      fn2 = ->
      stopGo.run(fn1).run(fn2)
      expect(stopGo.getQueue().length).toBe(2)
      stopGo.remove(fn1)
      expect(stopGo.getQueue().length).toBe(1)
      expect(stopGo.getQueue()[0]).toBe(fn2)


  describe 'shorthand syntax', ->
    describe 'when passed a function', ->
      it 'queues the function', ->
        stopGo = new StopGo()
        result = ''
        stopGo -> result += 'a'
        stopGo -> result += 'b'
        expect(result).toBe('')
        stopGo.go()
        expect(result).toBe('ab')

    describe 'when passed true', ->
      it 'calls go() internally', ->
        stopGo = new StopGo()
        result = ""
        stopGo -> result += "a"
        stopGo -> result += "b"
        expect(result).toBe("")
        stopGo(true)
        expect(result).toBe("ab")


    describe 'when passed false', ->
      it 'calls stop() inernally', ->
        stopGo = new StopGo()
        result = ''
        stopGo -> result += 'a'
        stopGo ->
          result += 'b'
          stopGo(false)
          stopGo ->
            result += 'c'
        expect(result).toBe('')
        stopGo(true)
        expect(result).toBe('ab')
        stopGo(true)
        expect(result).toBe('abc')


  describe 'multiple StopGo instances', ->
    describe 'when the outer StopGo is green before the inner', ->
      it 'executes the outer StopGo, and waits for the inner before completing', ->
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


    describe 'when the inner StopGo is green before the outer', ->
      it 'delays execution of both queues until the outer StopGo is green', ->
        sg1 = new StopGo()
        sg2 = new StopGo()

        result = ''
        sg1 ->
          result += 'a'
          sg2 ->
            result += 'b'

        expect(result).toBe('')
        sg2(true)
        expect(result).toBe('')
        sg1(true)
        expect(result).toBe('ab')


  describe 'StopGo.when', ->
    it 'composes a chain of StopGos', ->
      sg1 = new StopGo()
      sg2 = new StopGo()

      result = ''
      StopGo.when sg1, sg2, -> result = 'a'
      expect(result).toBe('')
      sg1(true)
      expect(result).toBe('')
      sg2(true)
      expect(result).toBe('a')


  describe 'when go() is called from a function that\'s being flushed', ->
    it 'succeeds without entering an infinite loop', ->
      sg = new StopGo()
      ran = false
      sg ->
        sg.go()
        ran = true
      expect(ran).toBe(false)
      sg.go()
      expect(ran).toBe(true)


  describe 'when stop() and go() are called from a function that\'s being flushed', ->
    it 'succeeds without entering an infinite loop', ->
      sg = new StopGo()
      ran = false
      sg ->
        sg.stop()
        sg.go()
        ran = true
      expect(ran).toBe(false)
      sg.go()
      expect(ran).toBe(true)


  describe 'string command syntax', ->
    describe 'when "go" is passed as an argument via shorthand syntax', ->
      it 'executes go()', ->
        sg = new StopGo()
        expect(sg()).toBe(false)
        sg('go')
        expect(sg()).toBe(true)

    describe 'when "remove" is passed as an argument via shorthand syntax', ->
      it 'executes remove successfully', ->
        sg = new StopGo()
        fn = -> console.log 'to be removed'
        sg(fn)
        expect(sg('getQueue')[0]).toBe(fn)
        sg('remove', fn)
        expect(sg('getQueue').length).toBe(0)
