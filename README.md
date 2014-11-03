injectoR
========

Dependency injection for R

This is a very early draft and the interface may change.

This tool is meant to make development and faster making it clear what parts of your script
depend on what functionality as well as making this dependency injectable

```
define ('factorial', callback = function () {
  factorial <- function (n) {
    if (n < 1) 1 else n * factorial (n - 1);
  };
});

inject (callback = function (factorial) {
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
shim ('http://cran.at.r-project.org/src/contrib/Archive/agrmt/agrmt_1.31.tar.gz');

inject (callback = function (modes) {
  # do stuff modes()
});
```

You may optionally inject or provide a default value

```
define ('greeting', callback = function (name = "stranger") {
  print (paste ("Greetings,", name));
});

inject (callback = function (greeting) {});

define ('name', callback = function () { 'Bob' });

inject (callback = function (greeting) {});
```

You may specify dependencies explicitly (useful if the key contains illegal characters)

```
define ('!', callback = function () {
  factorial <- function (n) {
    if (n < 1) 1 else n * factorial (n - 1);
  };
});

inject (c ('!'), callback = function (factorial) {
  factorial (3);
});
```

You may scope your bindings

```
define ('highlander', callback = function () {
  print ('there must be only one');
}, scope = singleton); # and then try with scope = prototype

inject (c ('highlander', 'highlander', 'highlander'), callback = function (h1, h2, h3) {});
```

Extensible!

```
env <- list ();

define ('custom', c ('foo', 'bar'), callback = function (foo = 2, bar = 'bar') {
  # ...
}, scope = function (key, provider, environment) {
  # ...
}, env);
```