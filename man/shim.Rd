% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/injector.R
\name{shim}
\alias{shim}
\title{Shims libraries}
\usage{
shim(..., library.paths = .libPaths(), callback = function() binder,
  binder = .binder)
}
\arguments{
\item{...}{zero or more library names to shim binding each exported
variable to the binder; if a library name is specified in a named
list format (for example shim(s4='stats4',callback=function(s4.AIC)))
all exported variable names from that library will be prepended with
that name and a dot (as in the example); if a library cannot be
loaded, no bindings are created for that library and no errors are
thrown (but there is an error to console as reported by
requireNamespace)}

\item{library.paths}{to use for loading namespace}

\item{callback}{injected for convenience using the binder specified
after shim is completed, if omitted the call returns the binder}

\item{binder}{for this shim}
}
\value{
result of the callback if specified, binder otherwise
}
\description{
Shims libraries
}
\examples{
shim ('injectoR', callback = function (inject) inject, binder = binder ())
}

