# Changes of tests assertive of API integrity must necessitate bump in major version

describe ("Binder factory", {
  it ("Should be a function accepting a parent a callback function", {
    expect_true (is.function (binder));
    expect_equal (names (formals (binder)), c ('parent', 'callback'));
  });

  it ("Should create new binder", expect_true (is.environment (binder ())));

  it ("Should create new child binder", {
    b <- binder ();
    b2 <- binder (parent = b);
    expect_equal (parent.env (b2), b);
  });

  it ("Should inject callback", expect_true (binder (callback = function (binder) {
    expect_true (is.environment (binder));
    TRUE;
  })));
});

describe ("Singleton scope", {
  it ("Should be a function accepting key and provider", {
    expect_true (is.function (singleton));
    expect_equal (names (formals (singleton)), c ('key', 'provider'));
  });

  it ("Should provision", expect_equal (singleton ('foo', function () function () 'foo') () (), 'foo'));

  it ("Should cache provision", {
    called <- FALSE;
    scoped <- singleton ('c', function (c = 0) {
                                expect_false (called); called <<- TRUE;
                                function () c <<- c + 1;
                              });
    injected <- scoped ();
    expect_equal (injected (), 1);
    expect_equal (injected (), 2);
    expect_equal (scoped () (), 3);
  });
});

describe ("Default scope", {
  it ("Should be a function accepting key and provider", {
    expect_true (is.function (default));
    expect_equal (names (formals (default)), c ('key', 'provider'));
  });

  it ("Should provide on each injection", {
    called <- 0;
    scoped <- default ('c', function (c = 0) {
      called <<- called + 1;
      function () c <<- c + 1;
    });
    injected <- scoped ();
    expect_equal (injected (), 1);
    expect_equal (injected (), 2);
    expect_equal (scoped () (), 1);
    expect_equal (called, 2);
  });
});

describe ("Binding definition", {
  it ("Should be a function accepting key, factory, scope, and binder", {
    expect_true (is.function (define));
    expect_equal (names (formals (define)), c ('key', 'factory', 'scope', 'binder'));
  });

  it ("Should define bindings", {
    b <- binder ();
    define ('foo', function () 'foo', binder = b);
    expect_equal (ls (b), 'foo');
    expect_equal (b[[ 'foo' ]] (), 'foo');
  });
});

describe ("Multibinder definition", {
  it ("Should be a function accepting key, scope, combine function, and binder", {
    expect_true (is.function (multibind));
    expect_equal (names (formals (multibind)), c ('key', 'scope', 'combine', 'binder'));
  });

  it ("Multibinder aggregator should be a function accepting ... and scope", {
    b <- binder ();
    a <- multibind ('foo', b = binder ());
    expect_true (is.function (a));
    expect_equal (names (formals (a)), c ('...', 'scope'));
  });

  it ("Should define an unnamed multibinding", {
    b <- binder ();
    multibind ('foo', binder = b) (function () 'foo');
    expect_equal (ls (b), 'foo');
    expect_equal (b[[ 'foo' ]] (), list ('foo'));
  });

  it ("Should define a named multibinding", {
    b <- binder ();
    multibind ('bar', binder = b) (bar = function () 'bar');
    expect_equal (ls (b), 'bar');
    expect_equal (b[[ 'bar' ]] (), list (bar = 'bar'));
  });
});

describe ("Shim binding", {
  it ("Should be a function acepting ..., library.paths, callback, and binder", {
    expect_true (is.function (shim));
    expect_equal (names (formals (shim)), c ('...', 'library.paths', 'callback', 'binder'));
  });

  it ("Should shim package", {
    b <- binder ();
    shim ('injectoR', binder = b);
    expect_true ('define' %in% ls (b));
  });

  it ("Should shim named package", {
    b <- binder ();
    shim (i = 'injectoR', binder = b);
    expect_true ('i.define' %in% ls (b));
  });

  it ("Should shim and inject callback", expect_true (shim (i = 'injectoR', callback = function (i.inject) {
      expect_equal (names (formals (i.inject)), c ('callback', 'binder'));
      TRUE;
    }, binder = binder ())));
});

describe ("Injection", {
  it ("Should be a function accepting callback and binder", {
    expect_true (is.function (inject));
    expect_equal (names (formals (inject)), c ('callback', 'binder'));
  });

  it ("Should inject indepentent callback", expect_equal (inject (function () 1), 1));

  it ("Should inject defined indepentent beans into callback", {
    b <- binder ();
    define ('foo', function () 'foo', b = b);
    define ('bar', function () 'bar', b = b);
    expect_equal (inject (function (foo, bar) list (foo, bar), b), list ('foo', 'bar'));
  });

  it ("Should inject defined beans with transitive dependencies into callback", {
    b <- binder ();
    define ('three', function () 3, b = b);
    define ('power', function () p <- function (x, n) if (n < 1) 1 else x * p (x, n - 1), b = b);
    define ('cube', function (three, power) function (x) power (x, three), b = b);
    expect_equal (inject (function (cube) cube (2), b), 8);
  });

  it ("Should inject multibound beans", {
    b <- binder ();

    multibind ('foo', b = b) (one = function () 1)
    multibind ('foo', b = b) (two = function () 2);
    multibind ('foo', b = b) (three = function () 3);
    multibind ('foo', b = b) (four = function () 4);
    expect_equal (inject (function (foo) foo, b), list (one = 1, two = 2, three = 3, four = 4));
    
    multibind ('bar', b = b) (one = function () 1, two = function () 2);
    multibind ('bar', b = b) (three = function () 3, four = function () 4);
    expect_equal (inject (function (bar) bar, b), list (one = 1, two = 2, three = 3, four = 4));
  });

  it ("Should injected multibound beans with respected scopes", {
    b <- binder ();
    c <- function () { c <- 0; function () c <<- c + 1; };
    multibind ('foo', b = b) (p = c);
    multibind ('foo', b = b) (s = c, scope = singleton);
    expect_equal (inject (function (foo) list (p = foo$p (), s = foo$s ()), b), list (p = 1, s = 1));
    expect_equal (inject (function (foo) list (p = foo$p (), s = foo$s ()), b), list (p = 1, s = 2));
  });

  it ("Should allow circular dependencies scope", {
    b <- binder ();
    define ('f', function (f) function (x) if (x < 1) 1 else x * f (x - 1), b = b);
    expect_equal (inject (function (f) f (6), b), 720);
  });
});
