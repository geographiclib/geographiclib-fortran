foreach (TOOL ${TOOLS})
  add_executable (${TOOL} ${TOOL}.for)
  target_link_libraries (${TOOL} ${LIBNAME})
endforeach ()

foreach (TOOL ${NGSTOOLS})
  add_executable (${TOOL} ${TOOL}.for ngscommon.for)
  target_link_libraries (${TOOL} ${LIBNAME})
endforeach ()

# Make the compiler more picky (for TOOLS only)
set_target_properties (${TOOLS} PROPERTIES COMPILE_FLAGS "${EXTRA_FLAGS}")

# Deal with the large arrays planimeter declares
set_target_properties (planimeter PROPERTIES COMPILE_FLAGS
  "${EXTRA_FLAGS} -frecursive")
