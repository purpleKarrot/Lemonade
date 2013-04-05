
find_path(LibGit2_INCLUDE_DIR git2.h)

find_library(LibGit2_LIBRARY
  NAMES git2
  PATHS libgit2
  )

if(LibGit2_INCLUDE_DIR)
  file(STRINGS "${LibGit2_INCLUDE_DIR}/git2/version.h" LibGit2_VERSION
    REGEX "#define LIBGIT2_VERSION \\\"(.*)\\\""
    )
  string(REGEX REPLACE "#define LIBGIT2_VERSION \\\"(.*)\\\"" "\\1"
    LibGit2_VERSION ${LibGit2_VERSION}
    )
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibGit2
  REQUIRED_VARS LibGit2_LIBRARY LibGit2_INCLUDE_DIR
  VERSION_VAR LibGit2_VERSION
  )

mark_as_advanced(LibGit2_LIBRARY LibGit2_INCLUDE_DIR)
