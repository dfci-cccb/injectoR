# Reproducible package installer, much simpler alternative to packrat
#
# Author: levk

# Exports bootstrap()
(function () {
  .root = file.path (.libPaths () [1], "bootstrap");

  # Download and install packages from source, optionally takes a callback function
  # injecting the package library paths. If the callback function is provided, the
  # function is invoked and the result is returned, otherwise a list of library
  # locations is returned
  bootstrap <<- function (..., callback = NULL, root = .root) {
    locations <- NULL;

    for (source in c (...)) {
      locations <- c (locations,
                      location <- file.path (root,
                                             gsub ("/", .Platform$file.sep,
                                                   gsub ("\\.", "/",
                                                         gsub("[:?=*#]", "_", source)))));
      if (!file.exists (location)) tryCatch ({
        download.file (source, 'package', method = 'curl');
        dir.create (location, showWarnings = FALSE, recursive = TRUE);
        install.packages ('package', repos = NULL, type = 'source', lib = location);
      }, finally = { unlink ('package') });
    }

    if (is.null (callback)) locations else callback (locations);
  };
}) ();
