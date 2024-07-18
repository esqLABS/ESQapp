# Get dependencies for current directory ----
require(renv)
# Get the current directory name ----
renv_path <- file.path(getwd(), 'renv.lock')

# Make a snapshot of the current directory ----
message('--- LOG: snapshot for path: \n', renv_path)
renv::snapshot(lockfile = renv_path, type = 'all', prompt = FALSE)

# Remove renv_path variable ----
remove(renv_path)



# -------------- Dev notes --------------

### Unload renv ----
# detach("package:renv", unload=TRUE)

### Snapshot with a specific lockfile ----
# renv::snapshot(project = renv_path,  lockfile = '~/host/renv.lock', type = 'all', prompt = FALSE)
