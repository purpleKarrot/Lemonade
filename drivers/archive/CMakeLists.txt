#=============================================================================
# Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
#
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at
#   http://www.boost.org/LICENSE_1_0.txt
#=============================================================================

find_package(Vala 0.16 REQUIRED)

find_package(CURL REQUIRED)
find_package(LibArchive REQUIRED)
find_package(PkgConfig REQUIRED)

pkg_check_modules(GLIB REQUIRED
  gobject-2.0
  gio-2.0
  )

include_directories(
  ${CURL_INCLUDE_DIRS}
  ${GLIB_INCLUDE_DIRS}
  ${LibArchive_INCLUDE_DIRS}
  )

vala_precompile(VALA_C
  SOURCES
    downloader.vala
    extract.vala
  GENERATE_HEADER
    ar_driver
  PACKAGES
    posix
  CUSTOM_VAPIS
    vapi/libarchive.vapi
    vapi/libcurl.vapi
    vapi/libproxy-1.0.vapi
  )

lem_driver(archive
  ${VALA_C}
  archive.c
  )

target_link_libraries(archive
  ${CURL_LIBRARIES}
  ${GLIB_LIBRARIES}
  ${LibArchive_LIBRARIES}
  karrot
  proxy
  )
