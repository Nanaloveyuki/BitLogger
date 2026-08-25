///|
async test "native async file lifecycle flushes rotates and restarts" {
  if !@bitlogger.native_files_supported() {
    inspect(@bitlogger.native_files_supported(), content="false")
  } else {
    let path = "logs/bitlogger-async-native-e2e.log"
    let first_flushes : Ref[Int] = Ref(0)
    let first_sink = @bitlogger.file_sink_async(
      path,
      append=false,
      auto_flush=false,
      rotation=Some(@bitlogger.file_rotation(8, max_backups=1)),
      formatter=fn(rec) { rec.message },
    )
    let first = async_logger(
      first_sink,
      config=AsyncLoggerConfig::new(
        max_pending=4,
        overflow=AsyncOverflowPolicy::Blocking,
        max_batch=4,
        linger_ms=0,
        flush=AsyncFlushPolicy::Batch,
      ),
      min_level=@bitlogger.Level::Info,
      target="async.file.e2e",
      flush=fn(sink) {
        first_flushes.val += 1
        ignore(sink.flush())
      },
    )

    @async.with_task_group(group => {
      group.spawn_bg(() => first.run())
      first.info("first-record")
      first.shutdown()
    })

    inspect(first.is_closed(), content="true")
    inspect(first.has_failed(), content="false")
    inspect(first.pending_count(), content="0")
    inspect(first_flushes.val > 0, content="true")
    inspect(first_sink.path(), content="logs/bitlogger-async-native-e2e.log")
    inspect(first_sink.rotation_enabled(), content="true")
    inspect(first_sink.rotation_failures(), content="0")
    inspect(first_sink.write_failures(), content="0")
    inspect(first_sink.flush_failures(), content="0")
    inspect(first_sink.close(), content="true")

    let restart_flushes : Ref[Int] = Ref(0)
    let restarted_sink = @bitlogger.file_sink_async(
      path,
      append=true,
      auto_flush=false,
      rotation=Some(@bitlogger.file_rotation(8, max_backups=1)),
      formatter=fn(rec) { rec.message },
    )
    let restarted = async_logger(
      restarted_sink,
      config=AsyncLoggerConfig::new(
        max_pending=4,
        overflow=AsyncOverflowPolicy::Blocking,
        max_batch=4,
        linger_ms=0,
        flush=AsyncFlushPolicy::Shutdown,
      ),
      min_level=@bitlogger.Level::Info,
      target="async.file.e2e",
      flush=fn(sink) {
        restart_flushes.val += 1
        ignore(sink.flush())
      },
    )

    @async.with_task_group(group => {
      group.spawn_bg(() => restarted.run())
      restarted.info("second-record")
      restarted.shutdown()
    })

    inspect(restarted.is_closed(), content="true")
    inspect(restarted.has_failed(), content="false")
    inspect(restarted.pending_count(), content="0")
    inspect(restart_flushes.val, content="1")
    inspect(restarted_sink.rotation_enabled(), content="true")
    inspect(restarted_sink.rotation_failures(), content="0")
    inspect(restarted_sink.write_failures(), content="0")
    inspect(restarted_sink.flush_failures(), content="0")
    inspect(restarted_sink.close(), content="true")
  }
}
