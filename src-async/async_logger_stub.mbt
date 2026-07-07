///|
pub fn async_runtime_mode() -> AsyncRuntimeMode {
  @utils.compatibility_async_runtime_mode()
}

///|
pub fn async_runtime_supports_background_worker() -> Bool {
  ignore(all_async_runtime_modes())
  false
}
