# Find the Vala compiler (valac)
#
# This module determines wheter a Vala compiler is installed on the current
# system and where its executable is.
#
# Call the module using "find_package(Vala) from within your CMakeLists.txt.
#
# The following variables will be set after an invocation:
#
#  VALA_FOUND       Whether the vala compiler has been found or not
#  VALA_EXECUTABLE  Full path to the valac executable if it has been found
#  VALA_VERSION     Version number of the available valac
#  VALA_USE_FILE    Include this file to define the vala_precompile function
#
# Compile vala files to their c equivalents for further processing. 
#
# The "vala_precompile" function takes care of calling the valac executable on
# the given source to produce c files which can then be processed further using
# default cmake functions.
#
# The first parameter provided is a variable, which will be filled with a list
# of c files outputted by the vala compiler. This list can than be used in
# conjuction with functions like "add_executable" or others to create the
# neccessary compile rules with CMake.
#
# The following sections may be specified afterwards to provide certain options
# to the vala compiler:
#
# SOURCES
#   A list of .vala files to be compiled. Please take care to add every vala
#   file belonging to the currently compiled project or library as Vala will
#   otherwise not be able to resolve all dependencies.
#
# PACKAGES
#   A list of vala packages/libraries to be used during the compile cycle. The
#   package names are exactly the same, as they would be passed to the valac
#   "--pkg=" option.
#
# OPTIONS
#   A list of optional options to be passed to the valac executable. This can be
#   used to pass "--thread" for example to enable multi-threading support.
#
# CUSTOM_VAPIS
#   A list of custom vapi files to be included for compilation. This can be
#   useful to include freshly created vala libraries without having to install
#   them in the system.
#
# GENERATE_VAPI
#   Pass all the needed flags to the compiler to create an internal vapi for
#   the compiled library. The provided name will be used for this and a
#   <provided_name>.vapi file will be created.
#
# GENERATE_HEADER
#   Let the compiler generate a header file for the compiled code. There will
#   be a header file as well as an internal header file being generated called
#   <provided_name>.h and <provided_name>_internal.h
#
# The following call is a simple example to the vala_precompile macro showing
# an example to every of the optional sections:
#
#   find_package(Vala "0.12" REQUIRED)
#
#   vala_precompile(VALA_C
#     SOURCES
#       source1.vala
#       source2.vala
#       source3.vala
#     PACKAGES
#       gtk+-2.0
#       gio-1.0
#       posix
#     DIRECTORY
#       gen
#     OPTIONS
#       --thread
#     CUSTOM_VAPIS
#       some_vapi.vapi
#     GENERATE_VAPI
#       myvapi
#     GENERATE_HEADER
#       myheader
#     )
#
# Most important is the variable VALA_C which will contain all the generated c
# file names after the call.

#=============================================================================
# Copyright 2009-2010 Jakob Westhoff. All rights reserved.
# Copyright 2010-2013 Daniel Pfeifer
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#    1. Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#
#    2. Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY JAKOB WESTHOFF ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL JAKOB WESTHOFF OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# The views and conclusions contained in the software and documentation are those
# of the authors and should not be interpreted as representing official policies,
# either expressed or implied, of Jakob Westhoff
#=============================================================================

# Search for the valac executable in the usual system paths.
find_program(VALA_EXECUTABLE valac)
mark_as_advanced(VALA_EXECUTABLE)

# Determine the valac version
if(VALA_EXECUTABLE)
  execute_process(COMMAND ${VALA_EXECUTABLE} "--version"
    OUTPUT_VARIABLE VALA_VERSION
    OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  string(REPLACE "Vala " "" VALA_VERSION "${VALA_VERSION}")
endif(VALA_EXECUTABLE)

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Vala
  REQUIRED_VARS VALA_EXECUTABLE
  VERSION_VAR VALA_VERSION
  )

include(CMakeParseArguments)

function(vala_precompile output)
  cmake_parse_arguments(ARGS
    ""
    "DIRECTORY;GENERATE_HEADER;GENERATE_VAPI"
    "SOURCES;PACKAGES;OPTIONS;CUSTOM_VAPIS"
    ${ARGN}
    )

  if(ARGS_DIRECTORY)
    set(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ARGS_DIRECTORY})
  else()
    set(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
  endif()
  include_directories(${DIRECTORY})

  set(vala_pkg_opts "")
  foreach(pkg IN LISTS ARGS_PACKAGES)
    list(APPEND vala_pkg_opts "--pkg=${pkg}")
  endforeach()

  set(custom_vapi_arguments "")
  if(ARGS_CUSTOM_VAPIS)
    foreach(vapi IN LISTS ARGS_CUSTOM_VAPIS)
      if(${vapi} MATCHES ${CMAKE_SOURCE_DIR} OR ${vapi} MATCHES ${CMAKE_BINARY_DIR})
        list(APPEND custom_vapi_arguments ${vapi})
      else()
        list(APPEND custom_vapi_arguments ${CMAKE_CURRENT_SOURCE_DIR}/${vapi})
      endif()
    endforeach()
  endif()

  set(vapi_arguments "")
  if(ARGS_GENERATE_VAPI)
    list(APPEND out_files "${DIRECTORY}/${ARGS_GENERATE_VAPI}.vapi")
    set(vapi_arguments "--internal-vapi=${ARGS_GENERATE_VAPI}.vapi")

    # Header and internal header is needed to generate internal vapi
    if(NOT ARGS_GENERATE_HEADER)
      set(ARGS_GENERATE_HEADER ${ARGS_GENERATE_VAPI})
    endif()
  endif()

  set(header_arguments "")
  if(ARGS_GENERATE_HEADER)
    list(APPEND out_files "${DIRECTORY}/${ARGS_GENERATE_HEADER}.h")
    list(APPEND out_files "${DIRECTORY}/${ARGS_GENERATE_HEADER}_internal.h")
    list(APPEND header_arguments "--header=${DIRECTORY}/${ARGS_GENERATE_HEADER}.h")
    list(APPEND header_arguments "--internal-header=${DIRECTORY}/${ARGS_GENERATE_HEADER}_internal.h")
  endif()

  set(out_files "")
  foreach(src IN LISTS ARGS_SOURCES ARGS_UNPARSED_ARGUMENTS)
    set(vala_file "${CMAKE_CURRENT_SOURCE_DIR}/${src}")
    string(REGEX REPLACE "[.](gs|vala)$" ".vapi" fast_vapi "${DIRECTORY}/${src}")
    string(REGEX REPLACE "[.](gs|vala)$" ".deps" deps_file "${DIRECTORY}/${src}")
    string(REGEX REPLACE "[.](gs|vala)$" ".c" c_file "${DIRECTORY}/${src}")
    add_custom_command(OUTPUT ${fast_vapi}
      COMMAND ${VALA_EXECUTABLE} --fast-vapi=${fast_vapi} ${vala_file}
      DEPENDS ${vala_file}
      )
    set(fast_vapi_args)
    set(fast_vapi_depends)
    foreach(dep IN LISTS ARGS_SOURCES ARGS_UNPARSED_ARGUMENTS)
      if(NOT "${src}" STREQUAL "${dep}")
        string(REGEX REPLACE "[.](gs|vala)$" ".vapi" vapi "${DIRECTORY}/${dep}")
        list(APPEND fast_vapi_args "--use-fast-vapi=${vapi}")
        list(APPEND fast_vapi_depends "${vapi}")
      endif()
    endforeach()
    add_custom_command(OUTPUT ${c_file}
      COMMAND ${VALA_EXECUTABLE} -C ${vala_file}
        ${header_arguments}
        ${vapi_arguments}
        ${fast_vapi_args}
        --deps=${deps_file}
        "-b" ${CMAKE_CURRENT_SOURCE_DIR}
        "-d" ${DIRECTORY}
        ${vala_pkg_opts}
        ${ARGS_OPTIONS}
        ${custom_vapi_arguments}
      DEPENDS
        ${vala_file}
        ${fast_vapi_depends}
        ${ARGS_CUSTOM_VAPIS}
      )
    list(APPEND out_files "${c_file}")
  endforeach()
  set(${output} ${out_files} PARENT_SCOPE)
endfunction()
