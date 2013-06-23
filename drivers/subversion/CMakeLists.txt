#=============================================================================
# Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
#
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at
#   http://www.boost.org/LICENSE_1_0.txt
#=============================================================================

find_package(APR       REQUIRED)
find_package(SVN "1.6" REQUIRED COMPONENTS client delta diff fs subr wc)

include_directories(
  ${APR_INCLUDE_DIRS}
  ${SVN_INCLUDE_DIRS}
  )

lem_driver(subversion
  subversion.c
  )

target_link_libraries(subversion
  ${APR_LIBRARIES}
  ${SVN_LIBRARIES}
  karrot
  )
