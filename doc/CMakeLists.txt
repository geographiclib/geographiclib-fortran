configure_file (doxyfile.in doxyfile @ONLY)
set (FORSOURCES
  ../src/geodesic.inc
  ../tools/geoddirect.for
  ../tools/geodinverse.for
  ../tools/ngscommon.for
  ../tools/ngsforward.for
  ../tools/ngsinverse.for
  ../tools/planimeter.for)

add_custom_target (doc ALL
  DEPENDS ${CMAKE_CURRENT_BINARY_DIR}/html/index.html)

add_custom_command (OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/html/index.html
  DEPENDS ${FORSOURCES}
    ${CMAKE_CURRENT_BINARY_DIR}/doxyfile
    geodesic-for.dox
  COMMAND ${DOXYGEN_EXECUTABLE} doxyfile > doxygen.log
  COMMENT "Generating Fortran documentation tree")
