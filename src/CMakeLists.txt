#=============================================================================
# Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
#
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at
#   http://www.boost.org/LICENSE_1_0.txt
#=============================================================================

find_package(Boost "1.46" REQUIRED
  filesystem
  program_options
  system
  )
include_directories(${Boost_INCLUDE_DIRS})


add_executable(lem
  main.cpp
  )

target_link_libraries(lem
  ${Boost_LIBRARIES}
  ${Karrot_LIBRARIES}
  dl
  )

set(OUTPUT_DIR "${Lemonade_BINARY_DIR}/bin")
file(MAKE_DIRECTORY "${OUTPUT_DIR}")

add_custom_command(TARGET lem POST_BUILD COMMAND
  ${CMAKE_COMMAND} -E copy $<TARGET_FILE:lem> ${OUTPUT_DIR}
  )
