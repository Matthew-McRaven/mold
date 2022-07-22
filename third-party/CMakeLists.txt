set(XXHASH_BUILD_ENABLE_INLINE_API OFF) #optional
set(XXHASH_BUILD_XXHSUM OFF) #optional
add_subdirectory(xxhash/cmake_unofficial EXCLUDE_FROM_ALL)


add_library(rust-demangle EXCLUDE_FROM_ALL STATIC rust-demangle/rust-demangle.c) #optional
target_include_directories(rust-demangle PUBLIC rust-demangle)