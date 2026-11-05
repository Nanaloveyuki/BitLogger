///|
async fn remove_if_present_internal(path : String) -> Unit {
  let present = @fs.exists(path) catch { _ => false }
  if present {
    @fs.remove(path) catch {
      _ => ()
    }
  }
}

///|
/// Async file sink behavior on the native backend: async open, write, async
/// rotation, and failure accounting for deferred handles.
async test "async file sink writes and rotates through the async backend" {
  if !@bitlogger.native_files_supported() {
    inspect(@bitlogger.native_files_supported(), content="false")
  } else {
    let path = "logs/bitlogger-async-spec-rotate.log"
    remove_if_present_internal(path)
    remove_if_present_internal(path + ".1")
    let sink = file_sink_async(
      path,
      append=false,
      auto_flush=true,
      rotation=Some(@bitlogger.file_rotation(16, max_backups=1)),
      formatter=fn(rec) { rec.message },
    )
    inspect(sink.is_available(), content="true")
    inspect(sink.path(), content="logs/bitlogger-async-spec-rotate.log")

    sink.write_async(@bitlogger.Record::new(@bitlogger.Level::Info, "aaaaaa"))
    sink.write_async(@bitlogger.Record::new(@bitlogger.Level::Info, "bbbbbb"))
    inspect(sink.write_failures(), content="0")
    inspect(sink.rotation_failures(), content="0")
    inspect(sink.flush_failures(), content="0")
    inspect(@fs.file_size(path), content="14")

    // The third record exceeds the limit, so the async writer rotates first.
    sink.write_async(@bitlogger.Record::new(@bitlogger.Level::Info, "cccccc"))
    inspect(sink.write_failures(), content="0")
    inspect(sink.rotation_failures(), content="0")
    inspect(@fs.file_size(path), content="7")
    inspect(@fs.file_size(path + ".1"), content="14")

    let rotated = @fs.open(path + ".1", mode=@fs.ReadOnly)
    assert_eq(rotated.read_exactly(14), b"aaaaaa\nbbbbbb\n")
    rotated.close()
    let current = @fs.open(path, mode=@fs.ReadOnly)
    assert_eq(current.read_exactly(7), b"cccccc\n")
    current.close()

    inspect(sink.close(), content="true")
    remove_if_present_internal(path)
    remove_if_present_internal(path + ".1")
  }
}

///|
/// A deferred handle is opened by the first async write. A path that cannot be
/// opened is reported through `open_failures`, and the unusable handle is
/// cleared instead of being retried as a write failure forever.
async test "configured async file sink reports deferred open failures" {
  if !@bitlogger.native_files_supported() {
    inspect(@bitlogger.native_files_supported(), content="false")
  } else {
    let path = "logs/bitlogger-async-spec-missing-dir/deferred.log"
    let logger = build_async_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.LoggerConfig::new(
          target="async.file.deferred-open",
          sink=@bitlogger.SinkConfig::new(kind=@bitlogger.SinkKind::File, path~),
        ),
        async_config=AsyncLoggerConfig::new(
          max_pending=4,
          overflow=AsyncOverflowPolicy::Blocking,
          max_batch=4,
          linger_ms=0,
          flush=AsyncFlushPolicy::Shutdown,
        ),
      ),
    )
    inspect(logger.sink.file_open_failures(), content="0")
    inspect(logger.sink.file_available(), content="true")

    @async.with_task_group(group => {
      group.spawn_bg(() => logger.run())
      logger.info("cannot persist")
      logger.shutdown()
    })

    inspect(logger.sink.file_open_failures(), content="1")
    inspect(logger.sink.file_write_failures(), content="1")
    inspect(logger.sink.file_flush_failures(), content="0")
    inspect(logger.sink.file_available(), content="false")
    inspect(logger.sink.file_state().open_failures, content="1")
  }
}

///|
/// Config-built async loggers wrap a deferred file handle. The first write has
/// to perform the async open and then persist through the async backend.
async test "configured async file logger writes through the async backend" {
  if !@bitlogger.native_files_supported() {
    inspect(@bitlogger.native_files_supported(), content="false")
  } else {
    let path = "logs/bitlogger-async-spec-configured.log"
    remove_if_present_internal(path)
    let logger = build_async_logger(
      AsyncLoggerBuildConfig::new(
        logger=@bitlogger.LoggerConfig::new(
          target="async.file.configured",
          timestamp=false,
          sink=@bitlogger.SinkConfig::new(
            kind=@bitlogger.SinkKind::File,
            path~,
            append=false,
          ),
        ),
        async_config=AsyncLoggerConfig::new(
          max_pending=4,
          overflow=AsyncOverflowPolicy::Blocking,
          max_batch=1,
          linger_ms=0,
          flush=AsyncFlushPolicy::Shutdown,
        ),
      ),
    )
    inspect(logger.sink.file_available(), content="true")
    inspect(logger.sink.file_open_failures(), content="0")

    @async.with_task_group(group => {
      group.spawn_bg(() => logger.run())
      logger.info("configured")
      logger.shutdown()
    })

    inspect(logger.sink.file_open_failures(), content="0")
    inspect(logger.sink.file_write_failures(), content="0")
    inspect(logger.sink.file_flush_failures(), content="0")
    inspect(logger.sink.file_rotation_failures(), content="0")
    // The configured text formatter renders level, target, and message.
    let expected = "[INFO] [async.file.configured] configured\n"
    inspect(@fs.file_size(path), content="42")
    let file = @fs.open(path, mode=@fs.ReadOnly)
    assert_eq(file.read_exactly(expected.length()), @utf8.encode(expected))
    file.close()
    inspect(logger.sink.file_close(), content="true")
    remove_if_present_internal(path)
  }
}

///|
/// `reopen*` stay synchronous: they install a deferred handle, and the next
/// async write performs the open with the new policy.
async test "async file sink reopen defers the open to the next async write" {
  if !@bitlogger.native_files_supported() {
    inspect(@bitlogger.native_files_supported(), content="false")
  } else {
    let path = "logs/bitlogger-async-spec-reopen.log"
    remove_if_present_internal(path)
    let sink = file_sink_async(path, append=true, auto_flush=true, formatter=fn(
      rec,
    ) {
      rec.message
    })
    sink.write_async(@bitlogger.Record::new(@bitlogger.Level::Info, "first"))
    inspect(sink.reopen_truncate(), content="true")
    inspect(sink.append_mode(), content="false")
    inspect(sink.is_available(), content="true")
    // The reopen call itself did not touch the file.
    inspect(@fs.file_size(path), content="6")

    sink.write_async(@bitlogger.Record::new(@bitlogger.Level::Info, "second"))
    inspect(sink.write_failures(), content="0")
    let file = @fs.open(path, mode=@fs.ReadOnly)
    assert_eq(file.read_exactly(7), b"second\n")
    file.close()
    inspect(sink.close(), content="true")
    remove_if_present_internal(path)
  }
}
