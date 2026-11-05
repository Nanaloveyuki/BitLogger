///|
async test "synchronous native file backend preserves bytes Unicode offsets and close" {
  if @bitlogger.native_files_supported() {
    let path = "logs/sync-文件-🌙.log"
    let sink = @bitlogger.file_sink(path, append=false, formatter=fn(rec) {
      rec.message
    })
    let logger = @bitlogger.Logger::new(sink).with_timestamp(enabled=false)
    logger.info("雪🌙")
    logger.info("second")
    inspect(sink.write_failures(), content="0")
    let file = @fs.open(path, mode=@fs.ReadOnly)
    assert_eq(
      file.read_exactly(15),
      b"\xe9\x9b\xaa\xf0\x9f\x8c\x99\x0asecond\x0a",
    )
    file.close()
    inspect(sink.close(), content="true")
    inspect(sink.close(), content="false")
    logger.info("closed")
    inspect(sink.write_failures(), content="1")
    inspect(sink.reopen_append(), content="true")
    logger.info("tail")
    inspect(@fs.file_size(path), content="20")
    inspect(sink.reopen_truncate(), content="true")
    logger.info("new")
    let file = @fs.open(path, mode=@fs.ReadOnly)
    assert_eq(file.read_exactly(4), b"new\x0a")
    file.close()
    ignore(sink.close())
    @fs.remove(path)
  }
}

///|
async test "synchronous native rotation observes sparse sizes above four GiB" {
  if @bitlogger.native_files_supported() {
    let path = "logs/sync-sparse.log"
    let file = @fs.open(
      path,
      mode=@fs.WriteOnly,
      create_mode=@fs.CreateOrTruncate,
    )
    file.write_at(b"x"[:], position=4294967296L)
    file.close()
    let sink = @bitlogger.file_sink(
      path,
      append=true,
      rotation=Some(@bitlogger.file_rotation_i64(4294967297L)),
      formatter=fn(rec) { rec.message },
    )
    @bitlogger.Logger::new(sink).with_timestamp(enabled=false).info("next")
    inspect(sink.rotation_failures(), content="0")
    inspect(@fs.file_size(path + ".1"), content="4294967297")
    inspect(@fs.file_size(path), content="5")
    ignore(sink.close())
    @fs.remove(path)
    @fs.remove(path + ".1")
  }
}

///|
#cfg(platform="linux")
test "synchronous native write failures remain observable" {
  let sink = @bitlogger.file_sink("/dev/full", append=true, formatter=fn(rec) {
    rec.message
  })
  @bitlogger.Logger::new(sink).info("cannot persist")
  inspect(sink.write_failures(), content="1")
  ignore(sink.close())
}
