injectoR
========

Dependency injection for R

This is a very early draft and the interface may change. You may install the project directly
from github via ```devtools::install_github ('dfci-cccb/injectoR', ref = '0.0.7')```

========

Injector is meant to ease development making it clear what parts of your script depend on what
other functionality without cluttering your interface

```R
define ('three', function () 3)

define ('power', function () p <- function (x, n) if (n < 1) 1 else x * p (x, n - 1));

define ('cube', function (power, three) function (x) power (x, three));

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
})
```

You may optionally inject or provide a default value

```R
define ('greeting', function (name = "stranger") print (paste ("Greetings,", name)));

inject (function (greeting) {});

define ('name', function () 'Bob');

inject (function (greeting) {});
```

You may scope your bindings

```R
define ('counter', function () {
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

define ('foo', factory = function (bar = 'bar') {
  # Factory for foo
}, scope = function (key, provider) {
  # The scope is called at definition time and is injected with the
  # provider function; provider function takes no arguments and is
  # responsible for provisioning the dependency, the scope function
  # is responsible for appropriately calling it and caching result
  # when necessary. Provider is the wrapped factory injection call
}, binder = binder);
```