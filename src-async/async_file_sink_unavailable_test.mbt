///|
/// On a backend without file support the constructor must not double-count the
/// open failure that the deferred handle already recorded.
async test "async file sink counts one open failure on unavailable backends" {
  if @bitlogger.native_files_supported() {
    // Covered by the native file tests; this case is about other targets.
    inspect(@bitlogger.native_files_supported(), content="true")
  } else {
    let sink = file_sink_async("logs/unavailable-async.log")
    inspect(sink.is_available(), content="false")
    inspect(sink.open_failures(), content="1")
    inspect(sink.write_failures(), content="0")
    inspect(sink.flush_failures(), content="0")
    inspect(sink.close(), content="false")
  }
}
