# Dependency injection framework for R
# 
# Author: levk

# Exports: singleton, default, define(), shim(), inject()
(function () {
  # Default environment
  .binder <- new.env ();

  # The default scope, bindings of this scope are provisioned each time they are injected
  default <<- function (provider) provider;

  # Singleton scope, singleton bindings are provisioned once and cached 
  singleton <<- function (provider) {
    value <- NULL;
    function () if (is.null (value)) value <<- provider () else value;
  };

  # Defines a binding within the binder specified formed of key, factory and scope
  define <<- function (key, factory, scope = default, binder = .binder)
    binder[[ key ]] <- scope (function () inject (factory, binder));

  # Shims a package defining each exported variable
  shim <<- function (package, prefix = '', suffix = '', root = NULL, binder = .binder) {
    space <- loadNamespace (package, lib.loc = root);
    for (export in getNamespaceExports (space))
      (function (export)
        define (paste (prefix, export, suffix, sep = ''), 
                function () getExportedValue (space, export),
                singleton, binder)) (export);
  };

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
