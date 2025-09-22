# Get dependencies for current directory ----
require(renv)
# Sys.setenv(RENV_CONFIG_EXTERNAL_DOWNLOADER = "false")
# Sys.setenv(RENV_DOWNLOAD_FILE_METHOD = "libcurl")
# options(download.file.method = "libcurl", download.file.extra = NULL)
#
# # 2) (Optional) Ensure no user curl config is read in this session
# Sys.setenv(CURL_HOME = tempfile())
renv::snapshot(type = "explicit")


# -------------- Dev notes --------------

### Unload renv ----
# detach("package:renv", unload=TRUE)

### Snapshot with a specific lockfile ----
# renv::snapshot(project = renv_path,  lockfile = '~/host/renv.lock', type = 'all', prompt = FALSE)
