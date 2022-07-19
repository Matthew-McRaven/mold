file(GLOB_RECURSE sources CONFIGURE_DEPENDS "**/*.cc" "*.cc")
# Add executable called "helloDemo" that is built from the source files
# "demo.cxx" and "demo_b.cxx". The extensions are automatically found.
add_executable (pld ${sources})
target_compile_features(pld PRIVATE cxx_std_20)

# Link the executable to the Hello library. Since the Hello library has
# public include directories we will use those link directories when building
# helloDemo
target_link_libraries (pld libpld)
set_property(TARGET pld APPEND PROPERTY COMPILE_DEFINITIONS "MOLD_VERSION=\"${CMAKE_PROJECT_VERSION}\"")
# Rules to copy mold to root of project
add_custom_command(
    TARGET pld POST_BUILD
COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/pld ${PROJECT_SOURCE_DIR}/mold
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Copying mold"
    VERBATIM)
add_custom_command(
    TARGET pld POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E create_symlink  ./mold ${PROJECT_SOURCE_DIR}/ld
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Creating ld symlink"
    VERBATIM)
add_custom_command(
    TARGET pld POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E create_symlink ./mold ${PROJECT_SOURCE_DIR}/ld64
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Creating ld64 symlink"
    VERBATIM)
