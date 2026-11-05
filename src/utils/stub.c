// Portable open() flag computation for the synchronous file backend.
//
// The MoonBit side must not hard-code platform-specific numeric flags: O_CREAT,
// O_TRUNC, and O_APPEND differ between Linux and macOS. Letting the system
// headers decide keeps the backend correct on every POSIX platform without a
// per-platform MoonBit branch.

#include <fcntl.h>

// Returns the open(2) flags for the requested mode. When `nul_terminated` is
// non-zero the MoonBit caller appended a trailing zero byte to the path, which
// is what the C string API expects.
int moonbit_bitlogger_open_flags(int read_only, int create, int append, int truncate) {
  int flags = read_only ? O_RDONLY : O_WRONLY;
  if (create) {
    flags |= O_CREAT;
  }
  if (truncate) {
    flags |= O_TRUNC;
  }
  if (append) {
    flags |= O_APPEND;
  }
#ifdef O_CLOEXEC
  flags |= O_CLOEXEC;
#endif
  return flags;
}

// File creation mode used together with O_CREAT (0644).
int moonbit_bitlogger_create_mode(void) { return 0644; }
