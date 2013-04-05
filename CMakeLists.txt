#=============================================================================
# Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
#
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at
#   http://www.boost.org/LICENSE_1_0.txt
#=============================================================================

cmake_minimum_required(VERSION 2.8.7 FATAL_ERROR)
project(Lemonade C CXX)

list(APPEND CMAKE_MODULE_PATH "${Lemonade_SOURCE_DIR}/CMake")

find_package(APR REQUIRED)
find_package(Boost "1.46" REQUIRED COMPONENTS filesystem system)
find_package(CURL REQUIRED)
find_package(Karrot REQUIRED)
find_package(LibArchive REQUIRED)
find_package(LibGit2 REQUIRED)
find_package(PkgConfig REQUIRED)
find_package(SVN "1.6" REQUIRED COMPONENTS client delta diff fs subr wc)
find_package(Vala 0.16 REQUIRED)

pkg_check_modules(GLIB REQUIRED
  gio-2.0
  libproxy-1.0
  )

include_directories(
  ${APR_INCLUDE_DIRS}
  ${Boost_INCLUDE_DIRS}
  ${CURL_INCLUDE_DIRS}
  ${GLIB_INCLUDE_DIRS}
  ${Karrot_INCLUDE_DIRS}
  ${LibArchive_INCLUDE_DIRS}
  ${LibGit2_INCLUDE_DIR}
  ${SVN_INCLUDE_DIRS}
  )

vala_precompile(VALA_C
  SOURCES
    src/archive.vala
    src/cmake.vala
    src/downloader.vala
    src/driver.vala
    src/git.vala
    src/main.vala
    src/packagekit.vala
    src/progress.vala
  OPTIONS
    --use-fast-vapi=${Lemonade_SOURCE_DIR}/src/msi.vapi
    --use-fast-vapi=${Lemonade_SOURCE_DIR}/src/subversion.vapi
  PACKAGES
    gio-2.0
    posix
  CUSTOM_VAPIS
    vapi/karrot.vapi
    vapi/libarchive.vapi
    vapi/libcurl.vapi
    vapi/libgit2.vapi
    vapi/libproxy-1.0.vapi
  GENERATE_HEADER
    lemonade
  )

add_executable(lem
  ${VALA_C}
  src/msi.c
  src/subversion.c
  )

target_link_libraries(lem
  ${APR_LIBRARIES}
  ${Boost_LIBRARIES}
  ${CURL_LIBRARIES}
  ${GLIB_LIBRARIES}
  ${Karrot_LIBRARIES}
  ${LibArchive_LIBRARIES}
  ${LibGit2_LIBRARY}
  ${SVN_LIBRARIES}
  )
