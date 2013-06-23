#=============================================================================
# Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
#
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at
#   http://www.boost.org/LICENSE_1_0.txt
#=============================================================================

cmake_minimum_required(VERSION 2.8.7 FATAL_ERROR)
project(Lemonade)

enable_testing()

list(APPEND CMAKE_MODULE_PATH "${Lemonade_SOURCE_DIR}/CMake")

#find_package(Vala 0.16 REQUIRED)

#find_package(PkgConfig REQUIRED)
#pkg_check_modules(GLIB REQUIRED gobject-2.0)
#pkg_check_modules(Peas REQUIRED libpeas-1.0)

if(${CMAKE_CXX_COMPILER_ID} MATCHES Clang)
  set(CMAKE_CXX_FLAGS "-std=c++11 -stdlib=libstdc++")
  set(CMAKE_CXX_LINK_FLAGS "-std=c++11 -stdlib=libstdc++")
elseif(${CMAKE_CXX_COMPILER_ID} STREQUAL GNU)
  include(CheckCXXCompilerFlag)
  check_cxx_compiler_flag(-std=c++11 HAVE_STD11)
  if(HAVE_STD11)
    set(CMAKE_CXX_FLAGS -std=c++11)
  else()
    check_cxx_compiler_flag(-std=c++0x HAVE_STD0X)
    if(HAVE_STD0X)
      set(CMAKE_CXX_FLAGS -std=c++0x)
    endif()
  endif()
endif()

find_package(Karrot REQUIRED)
include_directories(${Karrot_INCLUDE_DIRS})

add_subdirectory(src)
add_subdirectory(drivers)
