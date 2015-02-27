# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

#' Dependency injection framework
#'
#' @author levk
#' @docType package
#' @name injectoR
NULL;

#' Root binder
.binder <- new.env (parent = emptyenv ());

#' Binder factory
#' 
#' @param parent of the new binder, injection will propagate up the 
#' parent stack looking for keys; if omitted defaults to root binder
#' @param callback called with the newly created binder and the
#' result is returned; if omitted just the new binder is returned
#' @return result of the injected callback if one is specified,
#' otherwise the new binder
#' @export
binder <- function (parent = .binder, callback = function (binder) binder)
  callback (new.env (parent = parent));

#' Singleton scope, bindings of this scope are provided once, on
#' initial demand
#' 
#' @param key of the new binding
#' @param provider unscoped delegate, no argument function responsible
#' for provision
#' @export
singleton <- function (key, provider)
  (function (value) function () if (is.null (value)) value <<- provider () else value) (NULL);

#' Default scope, bindings are provisioned each time a bean is
#' injected
#' 
#' @param key of the new binding
#' @param provider unscoped delegate, no argument function responsible
#' for provision
default <- function (key, provider) provider;

#' Creates a key to factory binding
#' 
#' @param key injectable bean identifier, this name is matched to a
#' parameter name during injection
#' @param factory responsible for provisioning of the bean, a factory
#' may accept any number of arguments in which case the framework will
#' attempt to inject the argument if a binding to the parameter name
#' exists; if it does not, that argument will not be injected, in
#' which case it is the factory's responsibility to deal with a
#' missing argument
#' @param scope of the bean, wraps the injected factory call
#' specifying provisioning strategy, if omitted a new bean instance
#' will be provisioned each time injection is requested; injectoR also
#' ships with with the singleton scope which will provide once and
#' cache the bean for subsequent calls. Interface allows for custom
#' scoping, the scope parameter must be a function accepting key (name)
#' and the provider - the wrapped injected factory call - a function
#' accepting no parameters responsible for actual provisioning
#' @param binder for this binding, if omitted the new binding is added
#' to the root binder
#' @export
define <- function (key, factory, scope = default, binder = .binder)
  binder[[ key ]] <- scope (key, function () inject (factory, binder));

#' Aggregates multiple factories under one key
#' 
#' @param key injectable bean identifier
#' @param scope of the bean, wraps the injected factory call
#' specifying provisioning strategy, if omitted a new bean instance
#' will be provisioned each time injection is requested; injectoR also
#' ships with with the singleton scope which will provide once and
#' cache the bean for subsequent calls. Interface allows for custom
#' scoping, the scope parameter must be a function accepting key (name)
#' and the provider - the wrapped injected factory call - a function
#' accepting no parameters responsible for actual provisioning
#' @param combine aggregation procedure for combination of context
#' and inherited values, a function accepting a list of injectable
#' values from the current binder context and a no argument function
#' to retrieve values of the parent context; if omitted will the binding
#' will aggregate all values
#' @param binder for this binding, if omitted the binding is added to
#' the root binder
#' @return a function accepting one or more factories for adding
#' elements to the binding; naming the factories will result in named
#' values injected; optionally accepts a scope for the bindings, if
#' omitted defaults to provide on injection; please be aware that the
#' scope is called without key for unnamed multibinding
#' @export
multibind <- function (key, scope = default,
                       combine = function (this, parent) c (this, parent ()), binder = .binder) 
  if (exists (key, envir = binder, inherits = FALSE)) attr (binder[[ key ]], 'multibind') else {
    providers <- list ();
    binder[[ key ]] <- scope (key, function () {
                                     parent <- parent.env (binder);
                                     combine (lapply (providers, function (provider) provider ()),
                                              function () if (exists (key, envir = parent)) get (key, envir = parent) ()
                                                          else list ())
                                   });
    attr (binder[[ key ]],
          'multibind') <- function (..., scope = default) {
                            factories <- list (...);
                            providers <<- c (providers,
                                             lapply (setNames (1:length (factories), names (factories)),
                                                     function (i) (
                                                       function (name, factory){
                                                         force (factory);
                                                         scope (force (name),
                                                                function ()
                                                                  inject (factory, binder))
                                                       }) (names (factories)[ i ], factories[[ i ]])));
                          };
  };

#' Shims libraries
#' 
#' @param ... zero or more library names to shim binding each exported
#' variable to the binder; if a library name is specified in a named
#' list format (for example shim(s4='stats4',callback=function(s4.AIC)))
#' all exported variable names from that library will be prepended with
#' that name and a dot (as in the example); if a library cannot be
#' loaded, no bindings are created and no errors are thrown
#' @param library.paths to use for loading namespace
#' @param callback injected for convenience using the binder specified
#' after shim is completed, if omitted the call returns the binder
#' @param binder for this shim
#' @return result of the callback if specified, binder otherwise
#' @export
shim <- function (..., library.paths = .libPaths (), callback = function () binder, binder = .binder) (
  function (packages) {
    lapply (1:length (packages),
            function (i)
              if (requireNamespace (packages[[ i ]], lib.loc = library.paths)) (
                function (namespace)
                  lapply (getNamespaceExports (namespace),
                          function (export, value = getExportedValue (namespace, export))
                            define (if (is.null (names (packages)) || "" == names (packages)[ i ]) export
                                    else paste (names (packages)[ i ], export, sep = '.'),
                                    function () value, singleton, binder))) (loadNamespace (packages[[ i ]],
                                                                             lib.loc = library.paths)));
    inject (callback, binder);
  }) (list (...));

#' Injects the callback function
#' 
#' @param callback function to inject, a function accepting arguments
#' to be matched to injectable keys; no errors are thrown if no binding
#' is found for a key, this is the intended mechanic for optional
#' injection, if the callback is able to deal with a missing argument
#' the argument becomes optional
#' @param binder containing the injectables, defaults to root binder if
#' omitted
#' @return result of the injected callback evaluation
#' @export
inject <- function (callback, binder = .binder) {
  args <- new.env (parent = environment (callback));
  lapply (names (formals (callback)),
          function (key)
            if (exists (key, envir = binder))
              makeActiveBinding (key,
                                 (function (value)
                                    function (x)
                                      if (!missing (x)) value <<- x
                                      else if (is.null (value)) value <<- get (key, envir = binder) ()
                                      else value) (NULL), args));
  eval (body (callback), args);
}
