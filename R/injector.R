# Dependency injection framework for R
# 
# Author: levk
###############################################################################

# Default framework environment global
.environment <- new.env ();

# Singleton scope handler; bindings of singleton scope are provided for once and cached
singleton <- function (key, provider, environment) {
  if (is.null (environment[[ key ]]$singleton))
    environment[[ key ]]$singleton <- provider ();

  environment[[ key ]]$singleton;
}

# Prototype scope handler, bindings of prototype scope are provided for every time they are injected
prototype <- function (key, provider, environment) {
  provider ();
}

# Binds a key
bind <- function (key, dependencies = c (), callback, scope = prototype, environment = .environment) {
  environment[[ key ]]$dependencies <- dependencies;
  environment[[ key ]]$callback <- callback;
  environment[[ key ]]$scope <- scope;
}

# Inject a callback function with dependencies
inject <- function (dependencies, callback, environment = .environment) {
  errors <- list ();
  onError <- function (error) { errors[[ length(errors) + 1 ]] <- error; }
  parameters <- list ();
  
  for (key in dependencies)
    if (is.null (environment[[ key ]]))
      onError (c ("Unbound key ", key))
    else tryCatch ({
        parameters[[ key ]] <- environment[[ key ]]$scope (key, function () {
                                                             inject (environment[[ key ]]$dependencies,
                                                                     environment[[ key ]]$callback);
                                                           }, environment);
      }, error = onError, warning = onError);

  if (length (errors) == 0) do.call (callback, parameters)
  else stop (errors);

}

bind ('greeting', callback = function () { 'from the first R DI framework' });
bind ('world', callback = function () { 'world' });
bind ('hello', dependencies = c ('world'), callback = function (world) { c ('hello', world) });
inject (c ('hello', 'greeting'), function (hello, greeting) { 
  print (c ("HELLO=", hello));
  print (c ("GREETING=", greeting));
});