[![Build Status](https://travis-ci.org/dfci-cccb/injectoR.svg?branch=master)](https://travis-ci.org/dfci-cccb/injectoR) [![Build Status](https://ci.appveyor.com/api/projects/status/github/dfci-cccb/injectoR?svg=true)] [![Coverage Status](https://coveralls.io/repos/dfci-cccb/injectoR/badge.svg)](https://coveralls.io/r/dfci-cccb/injectoR)

injectoR
========

Dependency injection for R

You can install the project directly via github with ```devtools::install_github ('dfci-cccb/injectoR')```

========

Injector is meant to ease development making it clear what parts of your script depend on what
other functionality without cluttering your interface

```R
define (three = function () 3)
        power = function (power) function (x, n) if (n < 1) 1 else x * power (x, n - 1),
        cube = function (power, three) function (x) power (x, three));

inject (function (cube) cube (4));
```

Define collections to accumulate bindings and have the collection injected as a (optionally
named) list

```R
add.food <- multibind ('food')

add.food (function () 'pizza');
multibind ('food') (function () 'ice cream');
add.food (pretzel = function () 'pretzel');

inject (function (food) food);
```

Shimming a library will define each of its globally exported variables. Shimming does not call
library() so it will not export variables in the global namespace. Shimming and injecting is
better than calling library() because it defines clear boundaries of dependency, and while an
original result may depend on a library a derived will not have this explicit dependency 
allowing you to switch the original implementations at will

```R
shim ('agrmt');

inject (function (modes) {
  # do stuff with modes()
});

shim (s4 = 'stats4', callback = function (s4.AIC) {
  # do stuff with stats4's AIC()
});

# Useful idiom for shimming libraries in an anonymous binder without
# polluting the root binder (or whatever binder you're using)
shim (b = 'base', s = 'stats',
      callback = function (b.loadNamespace, b.getNamespaceExports, s.setNames) {
  # Define something useful into your root binder
  define ('exports', function () function (...) {
    packages = c (...);
    lapply (s.setNames (nm = packages), function (package)
      b.getNamespaceExports (b.loadNamespace (package)));
  });
}, binder = binder ());
```

You may optionally inject or provide a default value

```R
define (greeting = function (name = "stranger") print (paste ("Greetings,", name)));

inject (function (greeting) {});

define (name = function () 'Bob');

inject (function (greeting) {});
```

You may scope your bindings

```R
define (counter = function () {
  count <- 0;
  function () count <<- count + 1;
}, singleton);

inject (function (counter) {
  print (counter ());
});

inject (function (counter) {
  print (counter ());
});
```

Extensible!

```R
# Provide your own binding environment
binder <- binder ();

define (foo = function (bar = 'bar') {
  # Factory for foo
}, scope = function (provider) {
  # The scope is called at definition time and is injected with the
  # provider function; provider function takes no arguments and is
  # responsible for provisioning the dependency, the scope function
  # is responsible for appropriately calling it and caching result
  # when necessary. Provider is the wrapped factory injection call
}, binder = binder);
```