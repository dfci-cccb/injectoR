# Dependency injection framework for R
# 
# Author: levk

# Exports: singleton, default, define(), collection(), shim(), inject()
(function () {
  # Creates binders. Optionally accepts a callback function which will be called with the
  # newly created binder and returns the result of the callback, if no callback is provided
  # then returns the binder
  binder <<- function (parent = emptyenv (), callback = function (binder) binder) {
    result <- new.env (parent);
    result$binder <- function () result;
    callback (result);
  };

  # Default environment
  .binder <- binder ();

  # The default scope, bindings of this scope are provisioned each time they are injected
  default <<- function (provider) provider;

  # Singleton scope, singleton bindings are provisioned once and cached 
  singleton <<- function (provider) {
    value <- NULL;
    function () if (is.null (value)) value <<- provider () else value;
  };

  # Eager singleton scope for immediate evaluation at definition time
  eager <<- function (provider) {
    value <- provider ();
    function () value;
  }

  # Defines a binding within the binder specified formed of key, factory and scope
  define <<- function (key, factory, scope = default, binder = .binder)
    binder[[ key ]] <- scope (function () inject (factory, binder));

  # Defines an accumulative binding injectable as a list, returns the attachment function
  # which accepts an injectable factory function to append to the binding
  collection <<- function (key, scope = default, binder = .binder) {
    factories <- NULL;
    define (key, function () {
      collection <- list ();
      for (factory in factories) collection [[ length (collection) + 1 ]] <- inject (factory, binder);
      return (collection);
    }, scope, binder);
    function (factory) factories <<- c (factories, factory);
  }

  # Shims a package defining each exported variable
  shim <<- function (package, prefix = '', suffix = '', root = NULL, binder = .binder, required = TRUE)
    tryCatch (for (export in getNamespaceExports (loadNamespace (package, lib.loc = root)))
               (function (export)
                 define (paste (prefix, export, suffix, sep = ''),
                         function () getExportedValue (space, export),
                         singleton, binder)) (export),
              error = function (error) if (required) stop (error) else return ());

  # Launches the injected callback
  inject <<- function (callback, binder = .binder) {
    arguments <- list ();
    errors <- list ();

    for (key in names (formals (callback)))
      if (!is.null (binder[[ key ]]))
        tryCatch (arguments[[ key ]] <- binder[[ key ]] (), error = function (chain) errors <<- c (errors, chain));

    if (length (errors) == 0) do.call (callback, arguments) else stop (errors);
  };
}) ();
