configure_file (doxyfile-for.in doxyfile-for @ONLY)
file (GLOB CSOURCES ../src/*.for ../src/*.inc ../tools/*.for)
add_custom_target (doc ALL
  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/html/index.html)
add_custom_command (OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/html/index.html
  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/doxyfile-for geodesic-for.dox ${CSOURCES}
  COMMAND ${DOXYGEN_EXECUTABLE} doxyfile-for > doxygen-for.log
  COMMENT "Generating C documentation tree")
