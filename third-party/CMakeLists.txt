set(BUILD_SHARED_LIBS OFF)
set(TBB_TEST OFF CACHE INTERNAL "")
set(TBB_STRICT OFF CACHE INTERNAL "")
add_subdirectory(tbb EXCLUDE_FROM_ALL)
target_compile_definitions(tbb PRIVATE __TBB_DYNAMIC_LOAD_ENABLED=0)

set(XXHASH_BUILD_ENABLE_INLINE_API OFF) #optional
set(XXHASH_BUILD_XXHSUM OFF) #optional
add_subdirectory(xxhash/cmake_unofficial EXCLUDE_FROM_ALL)


add_library(rust-demangle EXCLUDE_FROM_ALL STATIC rust-demangle/rust-demangle.c) #optional
target_include_directories(rust-demangle PUBLIC rust-demangle)