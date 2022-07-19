file(GLOB_RECURSE sources CONFIGURE_DEPENDS "**/*.cc" "*.cc")

add_library (libpld STATIC ${sources})
target_compile_features(libpld PRIVATE cxx_std_20)

find_package(OpenSSL REQUIRED COMPONENTS Crypto)
find_package(ZLIB REQUIRED)

target_link_libraries(libpld LINK_PUBLIC tbb xxHash::xxhash rust-demangle OpenSSL::Crypto ZLIB::ZLIB)

target_include_directories (libpld PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

set_property(TARGET libpld APPEND PROPERTY COMPILE_DEFINITIONS "MOLD_VERSION=\"${CMAKE_PROJECT_VERSION}\"")
