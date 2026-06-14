#include <stdint.h>

#ifndef _CRT_SECURE_NO_WARNINGS
#define _CRT_SECURE_NO_WARNINGS
#endif

#include <stdio.h>

int32_t bitlogger_pointer_is_null(void *ptr) {
  return ptr == 0;
}

void *bitlogger_file_open(const char *path, const char *mode) {
#if defined(__clang__)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#endif
  return fopen(path, mode);
#if defined(__clang__)
#pragma clang diagnostic pop
#endif
}

int32_t bitlogger_file_write(const char *buffer, int32_t size, int32_t count, void *handle) {
  return (int32_t)fwrite(buffer, (size_t)size, (size_t)count, (FILE *)handle);
}

int32_t bitlogger_file_flush(void *handle) {
  return fflush((FILE *)handle);
}

int32_t bitlogger_file_close(void *handle) {
  return fclose((FILE *)handle);
}

int32_t bitlogger_file_seek(void *handle, int32_t offset, int32_t origin) {
  return fseek((FILE *)handle, offset, origin);
}

int32_t bitlogger_file_tell(void *handle) {
  long position = ftell((FILE *)handle);
  return position < 0 ? -1 : (int32_t)position;
}

int32_t bitlogger_file_rename(const char *from_path, const char *to_path) {
  return rename(from_path, to_path);
}

int32_t bitlogger_file_remove(const char *path) {
  return remove(path);
}
