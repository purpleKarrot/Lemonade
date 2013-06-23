#=============================================================================
# Copyright (C) 2013 Daniel Pfeifer <daniel@pfeifer-mail.de>
#
# Distributed under the Boost Software License, Version 1.0.
# See accompanying file LICENSE_1_0.txt or copy at
#   http://www.boost.org/LICENSE_1_0.txt
#=============================================================================

pkg_check_modules(Gvc REQUIRED
  libgvc
  )

vala_precompile(VALA_C
  SOURCES
    graph.vala
  PACKAGES
    libgvc
  OPTIONS
    --target-glib=2.36
  #CUSTOM_VAPIS
  # ${Lemonade_BINARY_DIR}/src/Lem-1.0.vapi
  )

add_executable(graph_foo
  ${VALA_C}
  )

target_link_libraries(graph_foo
  ${Gvc_LIBRARIES}
  )
