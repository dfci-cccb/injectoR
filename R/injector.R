# Dependency injection framework for R
# 
# Author: levk

# Exports: singleton, default, define(), shim(), inject()
(function () {
  # Default environment
  .environment <- new.env ();

  # The default scope, bindings of this scope are provisioned each time they are injected
  default <<- function (provider) { provider };

  # Singleton scope, singleton bindings are provisioned once and cached 
  singleton <<- function (provider) {
    value <- provider ();
    function () { value };
  };

  # Defines a binding formed of key, factory and scope
  define <<- function (key, factory, scope = default, environment = .environment) {
    environment[[ key ]] <- scope (function () { inject (factory, environment) });
  };

  # Shims a package defining each exported variable
  shim <<- function (package, prefix = '', root = NULL, environment = .environment) {
    space <- loadNamespace (package, lib.loc = root);
    for (export in getNamespaceExports (space))
      define (paste (prefix, export, sep = ''), function () { getExportedValue (space, export) }, singleton);
  };

  # Launches the injected callback
  inject <<- function (callback, environment = .environment) {
    errors <- list ();
    arguments <- list ();

    for (key in names (formals (callback)))
      if (is.null (environment[[ key ]])) {
        if (is.null (formals (callback)[[ key ]])) errors[[ length (errors) + 1 ]] <- paste ("Unbound non optional dependency on ", key);
      } else tryCatch ({ arguments[[ key ]] <- environment[[ key ]] () }, error = function (chain) { errors <- c (errors, chain) });

    if (length (errors) == 0) do.call (callback, arguments) else stop (errors);
  };
}) ();
