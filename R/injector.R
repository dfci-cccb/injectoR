# Dependency injection framework for R
# 
# Author: levk

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
define <- function (key, dependencies = NULL, callback, scope = prototype, environment = .environment) {
  environment[[ key ]]$dependencies <- if (is.null (dependencies)) names (formals (callback)) else dependencies;
  environment[[ key ]]$callback <- callback;
  environment[[ key ]]$scope <- scope;
}

# Shims a legacy package by binding each exported variable after installing it
# from source into a directory managed by the framework
shim <- function (source, environment = .environment) {
  location = file.path (.libPaths ()[1],
                        gsub ("/", .Platform$file.sep,
                              gsub ("//", "/", 
                                    paste ("injectoR/repository/",
                                           gsub ("\\.", "/", 
                                                 gsub("[:?=]", "_", source)), sep = ""))));
  tryCatch ({
    if (!file.exists (location)) {
      download.file (source, "package");
      dir.create (location, showWarnings = FALSE, recursive = TRUE);
      install.packages ("package", repos = NULL, type = "source", lib = location);
    }
    package <- installed.packages (lib.loc = location)[[ 1 ]];
    library (package, character.only = TRUE, lib.loc = location);
    
    for (export in ls (paste ("package:", package, sep = "")))
      define (export,
              callback = function () { eval (parse (text = export)) },
              scope = singleton,
              environment = environment);
  }, error = function (error) {
    unlink (location, recursive = TRUE);
    stop (error);
  }, finally = function () { unlink ("package"); });
}

# Inject a callback function with dependencies
inject <- function (dependencies = NULL, callback, environment = .environment) {
  errors <- list ();
  onError <- function (error) { errors[[ length(errors) + 1 ]] <- error; }
  parameters <- list ();

  for (key in if (is.null (dependencies)) names (formals (callback)) else dependencies) {
    name <- if (!is.null (dependencies)) names (formals (callback))[ length (parameters) + 1 ] else key;
    if (is.null (environment[[ key ]])) {
      if (is.null (formals (callback)[[ name ]])) # Has no default value and no binding
        onError (c ("Unbound dependency ", key));
    } else tryCatch ({
        parameters[[ name ]] <- environment[[ key ]]$scope (key, function () {
                                                               inject (environment[[ key ]]$dependencies,
                                                               environment[[ key ]]$callback);
                                                             }, environment);
      }, error = onError, warning = onError);
  }

  if (length (errors) == 0) do.call (callback, parameters)
  else stop (errors);
}

# Installs a module from repository
install <- function (key, version, repository = NULL) { stop ("Not yet implemented"); }

# Publishes a module to repository
publish <- function (key, version, repository = NULL) { stop ("Not yet implemented"); }