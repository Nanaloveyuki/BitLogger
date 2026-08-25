///|
test "file sink counts an injected partial backup-chain failure" {
  let test_path = "logs/file-runtime-rotate-partial-failure.log"
  ignore(@utils.remove_file_internal(test_path))
  ignore(@utils.remove_file_internal(test_path + ".1"))
  ignore(@utils.remove_file_internal(test_path + ".2"))

  let rotation = @file_model.file_rotation(20, max_backups=2)
  let seed = file_sink(test_path, auto_flush=true, rotation=Some(rotation), formatter=fn(
    rec,
  ) {
    rec.message
  })
  if seed.is_available() {
    @sink_graph.Sink::write(
      seed,
      @core.Record::new(@core.Level::Info, "1234567890"),
    )
    @sink_graph.Sink::write(
      seed,
      @core.Record::new(@core.Level::Info, "abcdefghij"),
    )
    inspect(seed.rotation_failures(), content="0")
    inspect(seed.close(), content="true")

    let sink = file_sink(test_path, auto_flush=true, rotation=Some(rotation), formatter=fn(
      rec,
    ) {
      rec.message
    })
    sink.rotation_file_ops.val = {
      file_exists: fn(candidate) { @utils.file_exists_internal(candidate) },
      remove_file: fn(candidate) { @utils.remove_file_internal(candidate) },
      rename_file: fn(from_path, to_path) {
        if from_path == test_path + ".1" && to_path == test_path + ".2" {
          false
        } else {
          @utils.rename_file_internal(from_path, to_path)
        }
      },
    }
    @sink_graph.Sink::write(
      sink,
      @core.Record::new(@core.Level::Info, "klmnopqrst"),
    )

    inspect(sink.rotation_failures(), content="1")
    inspect(sink.state().rotation_failures, content="1")
    inspect(sink.write_failures(), content="1")
    inspect(sink.is_available(), content="false")
    inspect(sink.reopen_append(), content="true")
    inspect(sink.is_available(), content="true")
    inspect(sink.close(), content="true")

    ignore(@utils.remove_file_internal(test_path))
    ignore(@utils.remove_file_internal(test_path + ".1"))
    ignore(@utils.remove_file_internal(test_path + ".2"))
  } else {
    inspect(native_files_supported(), content="false")
  }
}

///|
test "file sink counts an injected oldest-backup removal failure" {
  let test_path = "logs/file-runtime-rotate-removal-failure.log"
  ignore(@utils.remove_file_internal(test_path))
  ignore(@utils.remove_file_internal(test_path + ".1"))
  ignore(@utils.remove_file_internal(test_path + ".2"))

  let rotation = @file_model.file_rotation(20, max_backups=2)
  let seed = file_sink(test_path, auto_flush=true, rotation=Some(rotation), formatter=fn(
    rec,
  ) {
    rec.message
  })
  if seed.is_available() {
    @sink_graph.Sink::write(
      seed,
      @core.Record::new(@core.Level::Info, "1234567890"),
    )
    @sink_graph.Sink::write(
      seed,
      @core.Record::new(@core.Level::Info, "abcdefghij"),
    )
    inspect(seed.close(), content="true")

    let oldest = @utils.open_file_handle_internal(test_path + ".2", true)
    inspect(oldest is Some(_), content="true")
    match oldest {
      None => ()
      Some(handle) =>
        inspect(@utils.close_file_handle_internal(handle), content="true")
    }

    let sink = file_sink(test_path, auto_flush=true, rotation=Some(rotation), formatter=fn(
      rec,
    ) {
      rec.message
    })
    sink.rotation_file_ops.val = {
      file_exists: fn(candidate) { @utils.file_exists_internal(candidate) },
      remove_file: fn(candidate) {
        if candidate == test_path + ".2" {
          false
        } else {
          @utils.remove_file_internal(candidate)
        }
      },
      rename_file: fn(from_path, to_path) {
        @utils.rename_file_internal(from_path, to_path)
      },
    }
    @sink_graph.Sink::write(
      sink,
      @core.Record::new(@core.Level::Info, "klmnopqrst"),
    )

    inspect(sink.rotation_failures(), content="1")
    inspect(sink.write_failures(), content="1")
    inspect(sink.is_available(), content="false")
    inspect(sink.close(), content="false")

    ignore(@utils.remove_file_internal(test_path))
    ignore(@utils.remove_file_internal(test_path + ".1"))
    ignore(@utils.remove_file_internal(test_path + ".2"))
  } else {
    inspect(native_files_supported(), content="false")
  }
}
