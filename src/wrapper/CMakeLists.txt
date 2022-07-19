add_library(mold-wrapper SHARED)
set_target_properties(mold-wrapper PROPERTIES PREFIX "")
target_link_libraries(mold-wrapper PRIVATE ${CMAKE_DL_LIBS})
target_sources(mold-wrapper PRIVATE mold-wrapper.c)
target_compile_features(mold-wrapper PRIVATE cxx_std_20)


# Rules to copy mold-wrapper to root of project
add_custom_command(
    TARGET mold-wrapper POST_BUILD
COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/mold-wrapper.so ${PROJECT_SOURCE_DIR}/mold-wrapper.so
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Copying mold-wrapper.so"
    VERBATIM)