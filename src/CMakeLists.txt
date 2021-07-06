add_library (${LIBNAME} geodesic.for geodesic.inc)

target_include_directories (${LIBNAME} PUBLIC
  $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/src>
  $<INSTALL_INTERFACE:include>)
