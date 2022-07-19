#include <string>
namespace mold {
#ifdef GIT_HASH
const std::string mold_version =
  "mold " MOLD_VERSION " (" GIT_HASH "; compatible with GNU ld)";
#else
const std::string mold_version =
  "mold " MOLD_VERSION " (compatible with GNU ld)";
#endif
}