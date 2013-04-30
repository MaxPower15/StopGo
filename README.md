# StopGo

Think of a firehose. When the hose's valve is clamped shut, no functions can
drip out. When the hose's valve is open, all the functions spray out as fast
as they can.

__You__ provide the functions and __StopGo__ provides the hose and the valve.

Now imagine multiple hoses and valves, all connected in a series. For 
the functions to spray out the end, all the valves need to be open.
Similarly, StopGo functions can be chained naturally via nesting, or 
explicitly chained with `StopGo.when(...)`.

You might be thinking, "Hm, this sounds pretty similar to Promises. Why 
the hell would I use StopGo when there are full-featured Promise 
libraries out there?" There are three key differences:

1. StopGo execution can be synchronous. For DOM event bindings that require user interaction, this can be very important.
2. The state of a StopGo can change from "stop" to "go" infinite times. In contrast, a Promise is designed to permanently remain in its first end state.
3. It's less code, and it will accomplish your most common goals with no problems.

That said, this repository also includes the StopGoPromise class to 
demonstrate that StopGo is very fundamental, and powerful enough 
to form the base of a Promise API implementation.


## Examples

### Create a ready function:

    myObject.ready = new StopGo();

### Queue a function:

    myObject.ready(myFunction);
    myObject.ready.run(myFunction);

### When ready is true, queued functions will run immediately.

    myObject.ready(true);
    myObject.ready.go();

### When ready is false, any new functions will be queued.

    myObject.ready(false);
    myObject.ready.stop();

### You can send additional arguments to the queued functions:

    myObject.ready(function(name) { console.log("Hi, " + name + "!"); });
    myObject.ready(true, "Max");

### Remove a function from the queue:

    myObject.ready.remove(myFunction);

### Get the queue:

    myObject.ready.getQueue();

### Set the queue, it's just an array of functions:

    myObject.ready.setQueue(newQueue);

### Chain by nesting

    sg1 = new StopGo();
    sg2 = new StopGo();
    sg1(function() {
      sg2(function() {
        console.log("sg1 and sg2 must both be open for this to run.");
      });
    });

### Chain using StopGo.when

    sg1 = new StopGo();
    sg2 = new StopGo();
    StopGo.when(sg1, sg2).run(function() {
      console.log("sg1 and sg2 must both be open for this to run.");
    });


# StopGoPromise

The StopGoPromise class uses StopGo to implement the Promise API. This 
is mostly an academic exercise, and isn't meant to replace any of the more 
robust Promise implementations. The purpose is to show just how flexible 
and powerful StopGo can be.

I based the StopGoPromise behavior on these descriptions of the Promise API:

- https://gist.github.com/domenic/3889970
- http://wiki.commonjs.org/wiki/Promises/A

I did not implement the progress handler.

Caveat: I'm not sure how the behavior of rejection forwarding is 
supposed to work, or if it's supposed to happen at all. In this 
implementation, if one promise is rejected, all the following promises 
are also rejected with the same arguments.
