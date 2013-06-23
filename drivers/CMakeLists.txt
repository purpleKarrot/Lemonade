#=============================================================================
# Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
#
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at
#   http://www.boost.org/LICENSE_1_0.txt
#=============================================================================

set(DRIVER_DIR "${Lemonade_BINARY_DIR}/bin/drivers")
file(MAKE_DIRECTORY "${DRIVER_DIR}")

set(DRIVER_TEST_SRC "${CMAKE_CURRENT_SOURCE_DIR}/test.c")

function(lem_driver name)
  add_library(${name} SHARED
    ${ARGN}
    )
  set_target_properties(${name} PROPERTIES
    PREFIX ""
    )
  add_custom_command(TARGET ${name} POST_BUILD COMMAND
    ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${name}> ${DRIVER_DIR}
    )
endfunction()

add_subdirectory(archive)
add_subdirectory(git)
add_subdirectory(msi)
add_subdirectory(packagekit)
add_subdirectory(subversion)
