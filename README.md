# Quick Overview

StopGo was created at Wistia as a way to delay actions until a condition is
met.

It's used in nearly every function of the Player API, and whenever a video is
uploaded to Wistia. At this point, it's definitely been battle tested.

Here's a very artificial example:

    var ready = new StopGo();

    // Queues the function for later because ready() is false.
    ready(function() {
      console.log("Ready, sir!");
    });

    // Prints "Ready, sir!" as soon as ready(true) is called.
    setTimeout(function() {
      ready(true);
    }, 1000);

    // Prints "Right away!" because ready() is already true.
    setTimeout(function() {
      ready(function() {
        console.log("Right away!");
      });
    }, 2000);

Now let's say you need data from two different sources before executing a 
method.

You could execute them serially (slow, can't do two things at once, not
reusable):

    getDataFromX(function() {
      getDataFromY(function() {
        console.log("Got it.");
      });
    });

You could execute them simultaneously and manage it yourself (repetitive and 
hard to manage):

    var hasDataFromX;
    function getDataFromXWrapper() {
      if (hasDataFromX) {
        if (hasDataFromY) {
          console.log("Good to go.");
        }
      } else {
        getDataFromXWrapper(function() {
          hasDataFromX = true;
          if (hasDataFromY) {
            console.log("Good to go.");
          }
        });
      }
    }

    var hasDataFromY;
    function getDataFromYWrapper() {
      if (hasDataFromY) {
        if (hasDataFromX) {
          console.log("Good to go.");
        }
      } else {
        getDataFromYWrapper(function() {
          hasDataFromY = true;
          if (hasDataFromX) {
            console.log("Good to go.");
          }
        });
      }
    }

Or you could use StopGo.

    var hasDataFromX = new StopGo();
    getDataFromX(function() {
      hasDataFromX(true);
    });

    var hasDataFromY = new StopGo();
    getDataFromY(function() {
      hasDataFromY(true);
    });

    StopGo.when(hasDataFromX, hasDataFromY).run(function() {
      console.log("Good to go!");
    });

Basically, if you're in callback hell, only Promises or StopGo can save you.

You might be thinking, "Hm, this sounds pretty similar to Promises. Why the
hell would I use StopGo when there are full-featured Promise libraries out
there?" There are three key differences:

1. StopGo execution can be synchronous. For DOM event bindings that require user interaction, this can be very important.
2. The state of a StopGo can change from "stop" to "go" an infinite number of times. In contrast, a Promise is designed to permanently remain in its first terminal state.
3. It's less code, and it handles the most useful aspects of promises without requiring deep integration.

That said, this repository also includes the StopGoPromise class to demonstrate
that StopGo is very fundamental, and powerful enough to form the base of a
Promise API implementation.

Let me be clear: the Promise API is awesome and highly useful. But I think
StopGo is really cool too, and has its own place in the Javascript world.


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

The StopGoPromise class uses StopGo to implement the Promise API. This is
mostly an academic exercise, and isn't meant to replace any of the more robust
Promise implementations. The purpose is to show just how flexible and powerful
StopGo can be.

I based the StopGoPromise behavior on these descriptions of the Promise API:

- https://gist.github.com/domenic/3889970
- http://wiki.commonjs.org/wiki/Promises/A

I did not implement the progress handler.

Caveat: I'm not sure how the behavior of rejection forwarding is supposed to
work, or if it's supposed to happen at all. In this implementation, if one
promise is rejected, all the following promises are also rejected with the same
arguments.
