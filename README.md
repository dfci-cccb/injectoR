injectoR
========

Dependency injection for R

This is a very early draft and the interface may change. You may use the current state of
the injector with the following:

```
(function (...) { for (url in c (...)) tryCatch ({ download.file (url, 'source', method = 'curl'); source ('source'); }, finally = { unlink ('source'); }); }) ('https://raw.githubusercontent.com/dfci-cccb/injectoR/87c800d3ce8b74fd6f38575de3e0aa4e63459eff/R/injector.R');
```
========


Injector is meant to make development and faster making it clear what parts of your script
depend on what functionality as well as making this dependency injectable

```
define ('factorial', function () {
  factorial <- function (n) {
    if (n < 1) 1 else n * factorial (n - 1);
  };
});

inject (function (factorial) {
  factorial (3);
});
```

You may shim legacy libraries; shimming libraries requires an install from source and allows
installation (but not attachment) of different versions of the same library. Shimming a library
will define all its globally exported variables.

Shimming is meant as a crutch which at least makes it clear from the listing of a script which
version of a library it is supposed to run - if not outright work years after it was written.
Ideally ofcourse people would use the module definition system laid out here for writing scripts

```
shim ('agrmt');

inject (function (modes) {
  # do stuff modes()
});
```

You may optionally inject or provide a default value

```
define ('greeting', function (name = "stranger") {
  print (paste ("Greetings,", name));
});

inject (function (greeting) {});

define ('name', callback = function () { 'Bob' });

inject (function (greeting) {});
```

You may scope your bindings

```
define ('counter', function () {
  count <- 0;
  function () { count <<- count + 1 }
}, singleton);

define ('counter2', function () {
  count <- 0;
  function () { count <<- count + 1 }
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

```
# Provide your own environment
env <- list ();

define ('foo', function (bar = 'bar') {
  # ...
}, scope = function (provider) {
  # The scope is called at definition time and is injected with the
  # provider function; provider function takes no arguments and is
  # responsible for provisioning the dependency, the scope function
  # is responsible for appropriately calling it and caching result
  # when necessary
}, env);
```