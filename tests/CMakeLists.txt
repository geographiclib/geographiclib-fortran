foreach (TEST ${TESTS})
  add_executable (${TEST} ${TEST}.for)
  target_link_libraries (${TEST} ${LIBNAME})
endforeach ()

# Make the compiler more picky
set_target_properties (${TESTS} PROPERTIES COMPILE_FLAGS "${EXTRA_FLAGS}")
