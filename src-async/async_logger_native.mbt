pub fn async_runtime_mode() -> AsyncRuntimeMode {
  @utils.native_worker_async_runtime_mode()
}

pub fn async_runtime_supports_background_worker() -> Bool {
  ignore(all_async_runtime_modes())
  true
}

fn async_runtime_guard_closed_on_log() -> Bool {
  false
}

fn async_runtime_shutdown_clears_pending_after_wait_idle() -> Bool {
  true
}

fn async_runtime_shutdown_waits_for_worker() -> Bool {
  true
}
