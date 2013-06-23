#=============================================================================
# Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
#
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at
#   http://www.boost.org/LICENSE_1_0.txt
#=============================================================================

find_package(LibGit2 REQUIRED)
include_directories(${LibGit2_INCLUDE_DIRS})

lem_driver(git
  git.c
  )

target_link_libraries(git
  ${LibGit2_LIBRARY}
  karrot
  )
