#include "mold.h"
#include "../sha.h"

#include <filesystem>
#include <signal.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

namespace mold::elf {

template <typename E>
static std::string find_dso(Context<E> &ctx, std::filesystem::path self) {
  // Look for mold-wrapper.so from the same directory as the executable is.
  std::filesystem::path path = self.parent_path() / "mold-wrapper.so";
  std::error_code ec;
  if (std::filesystem::is_regular_file(path, ec) && !ec)
    return path;

#ifdef LIBDIR
  // If not found, search $(LIBDIR)/mold, which is /usr/local/lib/mold
  // by default.
  path = LIBDIR "/mold/mold-wrapper.so";
  if (std::filesystem::is_regular_file(path, ec) && !ec)
    return path;
#endif

  // Look for ../lib/mold/mold-wrapper.so
  path = self.parent_path() / "../lib/mold/mold-wrapper.so";
  if (std::filesystem::is_regular_file(path, ec) && !ec)
    return path;

  Fatal(ctx) << "mold-wrapper.so is missing";
}

template <typename E>
[[noreturn]]
void process_run_subcommand(Context<E> &ctx, int argc, char **argv) {
#ifdef __APPLE__
  // LD_PRELOAD is not supported on macOS
  Fatal(ctx) << "mold -run is not supported on macOS";
#endif

  std::string_view arg1 = argv[1];
  assert(arg1 == "-run" || arg1 == "--run");
  if (!argv[2])
    Fatal(ctx) << "-run: argument missing";

  // Get the mold-wrapper.so path
  std::string self = std::filesystem::read_symlink("/proc/self/exe");
  std::string dso_path = find_dso(ctx, self);

  // Set environment variables
  putenv(strdup(("LD_PRELOAD=" + dso_path).c_str()));
  putenv(strdup(("MOLD_PATH=" + self).c_str()));

  // If ld, ld.lld or ld.gold is specified, run mold itself
  if (std::string cmd = filepath(argv[2]).filename();
      cmd == "ld" || cmd == "ld.lld" || cmd == "ld.gold") {
    std::vector<char *> args;
    args.push_back(argv[0]);
    args.insert(args.end(), argv + 3, argv + argc);
    args.push_back(nullptr);
    execv(self.c_str(), args.data());
    Fatal(ctx) << "mold -run failed: " << self << ": " << errno_string();
  }

  // Execute a given command
  execvp(argv[2], argv + 2);
  Fatal(ctx) << "mold -run failed: " << argv[2] << ": " << errno_string();
}

#define INSTANTIATE(E)                                                  \
  template void process_run_subcommand(Context<E> &, int, char **)

INSTANTIATE_ALL;

} // namespace mold::elf
