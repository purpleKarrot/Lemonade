#=============================================================================
# Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
#
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at
#   http://www.boost.org/LICENSE_1_0.txt
#=============================================================================

find_package(Vala 0.16 REQUIRED)

find_package(PkgConfig REQUIRED)
pkg_check_modules(GLIB REQUIRED
  gobject-2.0
  gio-2.0
  )

include_directories(
  ${GLIB_INCLUDE_DIRS}
  )

vala_precompile(VALA_C
  SOURCES
    pk_driver.vala
  GENERATE_HEADER
    pk_driver
  PACKAGES
    gio-2.0
  CUSTOM_VAPIS
    vapi/karrot.vapi
  )

lem_driver(packagekit
  ${VALA_C}
  packagekit.c
  )

target_link_libraries(packagekit
  ${GLIB_LIBRARIES}
  karrot
  )
