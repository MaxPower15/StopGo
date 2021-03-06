// Generated by CoffeeScript 1.8.0
describe("StopGoPromise", function() {
  it("runs the success function when resolved", function() {
    var promise, result;
    promise = new StopGoPromise();
    result = "";
    promise.then((function() {
      return result = "a";
    }), (function() {
      return result = "b";
    }));
    expect(result).toBe("");
    promise.resolve();
    return expect(result).toBe("a");
  });
  it("runs the error function when rejected", function() {
    var promise, result;
    promise = new StopGoPromise();
    result = "";
    promise.then((function() {
      return result = "a";
    }), (function() {
      return result = "b";
    }));
    expect(result).toBe("");
    promise.reject();
    return expect(result).toBe("b");
  });
  it("StopGoPromise.when creates a new promise", function() {
    var p1, p2;
    p1 = new StopGoPromise();
    p2 = StopGoPromise.when(p1);
    expect(p2 instanceof StopGoPromise);
    return expect(p1 !== p2);
  });
  it("can chain with StopGoPromise.when", function() {
    var p1, p2, result;
    p1 = new StopGoPromise();
    p2 = new StopGoPromise();
    result = "";
    StopGoPromise.when(p1, p2).then((function() {
      return result = "a";
    }), (function() {
      return result = "b";
    }));
    expect(result).toBe("");
    p1.resolve();
    expect(result).toBe("");
    p2.resolve();
    return expect(result).toBe("a");
  });
  it("forwards rejection through the chain", function() {
    var p1, p2, result;
    p1 = new StopGoPromise();
    p2 = new StopGoPromise();
    result = "";
    StopGoPromise.when(p1, p2).then((function() {
      return result = "a";
    }), (function() {
      return result = "b";
    }));
    expect(result).toBe("");
    p1.reject();
    return expect(result).toBe("b");
  });
  it("forwards rejection through the chain (reject the other component)", function() {
    var p1, p2, result;
    p1 = new StopGoPromise();
    p2 = new StopGoPromise();
    result = "";
    StopGoPromise.when(p1, p2).then((function() {
      return result = "a";
    }), (function() {
      return result = "b";
    }));
    expect(result).toBe("");
    p2.reject();
    return expect(result).toBe("b");
  });
  it("preserves order of operations when being chained", function() {
    var p1, p2, result;
    p1 = new StopGoPromise();
    p2 = new StopGoPromise();
    result = "";
    p1.then(function() {
      return result += "a";
    });
    p1.then(function() {
      return result += "b";
    });
    p2.then(function() {
      return result += "c";
    });
    p2.then(function() {
      return result += "d";
    });
    p1.then(function() {
      return result += "e";
    }).then(p2);
    expect(result).toBe("");
    p1.resolve();
    expect(result).toBe("abe");
    p2.resolve();
    return expect(result).toBe("abecd");
  });
  it("forwards arguments through promises via return values", function() {
    var p1, p2, result;
    p1 = new StopGoPromise();
    p2 = new StopGoPromise();
    result = "";
    p1.then(p2).then(function(arg) {
      expect(arg).toBe("a");
      return arg + "b";
    }).then(function(arg) {
      expect(arg).toBe("ab");
      return result = arg + "c";
    }, function(arg) {
      return result = arg;
    });
    expect(result).toBe("");
    p1.resolve();
    expect(result).toBe("");
    p2.resolve("a");
    return expect(result).toBe("abc");
  });
  return it("forwards rejection when chained with then", function() {
    var p1, p2, result;
    p1 = new StopGoPromise();
    p2 = new StopGoPromise();
    result = "";
    p1.then(p2).then(function(arg) {
      expect(arg).toBe("a");
      return arg + "b";
    }).then(function(arg) {
      expect(arg).toBe("ab");
      return result = arg + "c";
    }, function(arg) {
      return result = "error: " + arg;
    });
    p1.reject("testing");
    return expect(result).toBe("error: testing");
  });
});
