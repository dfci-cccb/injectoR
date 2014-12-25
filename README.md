injectoR
========

Dependency injection for R

This is a very early draft and the interface may change. You may install the project directly
from github via devtools::install_packages ('dfci-cccb/injectoR'), you may reference the exact
commit revision to freeze your version

========


Injector is meant to make development and faster making it clear what parts of your script
depend on what functionality as well as making this dependency injectable

```R
define ('factorial', function ()
  factorial <- function (n)
    if (n < 1) 1 else n * factorial (n - 1));

inject (function (factorial)
  factorial (3));
```

You may define collections to accumulate bindings and have the collection injected as a list

```R
add.food <- collection ('food')

add.food (function () 'pizza');
add.food (function () 'ice cream');

inject (function (food) for (item in food) print (paste (item, "is bad for you")));
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

define ('counter2', function () {
  count <- 0;
  function () count <<- count + 1;
});

inject (function (counter, counter2) {
  print (counter ());
  print (counter2 ());
});

inject (function (counter, counter2) {
  print (counter ());
  print (counter2 ());
});
```

Extensible!

```R
# Provide your own binding environment
binder <- binder ();

define ('foo', factory = function (bar = 'bar') {
  # ...
}, scope = function (provider) {
  # The scope is called at definition time and is injected with the
  # provider function; provider function takes no arguments and is
  # responsible for provisioning the dependency, the scope function
  # is responsible for appropriately calling it and caching result
  # when necessary. Provider is the wrapped factory injection call
}, binder = binder);
```