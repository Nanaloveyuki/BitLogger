---
name: api-index
group: api
category: index
update-time: 20260512
description: API navigation index for BitLogger and bitlogger_async.
key-word:
    - api
    - index
    - logger
    - async
---

## Api-index

BitLogger API navigation.

## Core logger

- [logger-new.md](./logger-new.md)
- [logger-with-target.md](./logger-with-target.md)
- [logger-child.md](./logger-child.md)
- [logger-with-min-level.md](./logger-with-min-level.md)
- [logger-with-timestamp.md](./logger-with-timestamp.md)
- [logger-with-context-fields.md](./logger-with-context-fields.md)
- [logger-bind.md](./logger-bind.md)
- [logger-with-filter.md](./logger-with-filter.md)
- [logger-with-patch.md](./logger-with-patch.md)
- [logger-with-queue.md](./logger-with-queue.md)

## Logger write APIs

- [logger-is-enabled.md](./logger-is-enabled.md)
- [logger-log.md](./logger-log.md)
- [logger-trace.md](./logger-trace.md)
- [logger-debug.md](./logger-debug.md)
- [logger-info.md](./logger-info.md)
- [logger-warn.md](./logger-warn.md)
- [logger-error.md](./logger-error.md)

## Global logger helpers

- [set-default-min-level.md](./set-default-min-level.md)
- [set-default-target.md](./set-default-target.md)
- [default-logger.md](./default-logger.md)
- [global-log.md](./global-log.md)
- [global-trace.md](./global-trace.md)
- [global-debug.md](./global-debug.md)
- [global-info.md](./global-info.md)
- [global-warn.md](./global-warn.md)
- [global-error.md](./global-error.md)

## Formatter and fields

- [field.md](./field.md)
- [text-formatter.md](./text-formatter.md)
- [text-formatter-config.md](./text-formatter-config.md)
- [text-formatter-config-to-json.md](./text-formatter-config-to-json.md)
- [stringify-text-formatter-config.md](./stringify-text-formatter-config.md)
- [fields.md](./fields.md)

## Record and level

- [record-new.md](./record-new.md)
- [level-priority.md](./level-priority.md)
- [level-label.md](./level-label.md)
- [level-enabled.md](./level-enabled.md)

## Sink and file

- [file-sink.md](./file-sink.md)
- [file-rotation.md](./file-rotation.md)
- [file-sink-policy-to-json.md](./file-sink-policy-to-json.md)
- [stringify-file-sink-policy.md](./stringify-file-sink-policy.md)
- [file-sink-state-to-json.md](./file-sink-state-to-json.md)
- [stringify-file-sink-state.md](./stringify-file-sink-state.md)
- [runtime-file-state-to-json.md](./runtime-file-state-to-json.md)
- [stringify-runtime-file-state.md](./stringify-runtime-file-state.md)
- [sink-config.md](./sink-config.md)
- [sink-config-to-json.md](./sink-config-to-json.md)
- [stringify-sink-config.md](./stringify-sink-config.md)

## Predicates and helpers

- [level-at-least.md](./level-at-least.md)
- [target-is.md](./target-is.md)
- [target-has-prefix.md](./target-has-prefix.md)
- [message-contains.md](./message-contains.md)
- [has-field.md](./has-field.md)
- [field-equals.md](./field-equals.md)
- [not.md](./not.md)
- [all-of.md](./all-of.md)
- [any-of.md](./any-of.md)
- [identity-patch.md](./identity-patch.md)
- [set-target.md](./set-target.md)
- [prefix-message.md](./prefix-message.md)
- [append-fields.md](./append-fields.md)
- [redact-field.md](./redact-field.md)
- [redact-fields.md](./redact-fields.md)
- [compose-patches.md](./compose-patches.md)

## Config build flow

- [queue-config.md](./queue-config.md)
- [queue-config-to-json.md](./queue-config-to-json.md)
- [stringify-queue-config.md](./stringify-queue-config.md)
- [logger-config.md](./logger-config.md)
- [logger-config-to-json.md](./logger-config-to-json.md)
- [stringify-logger-config.md](./stringify-logger-config.md)
- [parse-logger-config-text.md](./parse-logger-config-text.md)
- [build-logger.md](./build-logger.md)
- [parse-and-build-logger.md](./parse-and-build-logger.md)

## Presets

- [console.md](./console.md)
- [json-console.md](./json-console.md)
- [text-console.md](./text-console.md)
- [file.md](./file.md)
- [with-queue.md](./with-queue.md)
- [with-file-rotation.md](./with-file-rotation.md)

## Async logger

- [async-logger.md](./async-logger.md)
- [async-logger-run.md](./async-logger-run.md)
- [async-logger-log.md](./async-logger-log.md)
- [async-logger-trace.md](./async-logger-trace.md)
- [async-logger-debug.md](./async-logger-debug.md)
- [async-logger-info.md](./async-logger-info.md)
- [async-logger-warn.md](./async-logger-warn.md)
- [async-logger-error.md](./async-logger-error.md)

## Async composition

- [async-logger-with-target.md](./async-logger-with-target.md)
- [async-logger-child.md](./async-logger-child.md)
- [async-logger-with-min-level.md](./async-logger-with-min-level.md)
- [async-logger-with-timestamp.md](./async-logger-with-timestamp.md)
- [async-logger-with-context-fields.md](./async-logger-with-context-fields.md)
- [async-logger-with-filter.md](./async-logger-with-filter.md)
- [async-logger-with-patch.md](./async-logger-with-patch.md)

## Async lifecycle and state

- [async-logger-pending-count.md](./async-logger-pending-count.md)
- [async-logger-dropped-count.md](./async-logger-dropped-count.md)
- [async-logger-is-closed.md](./async-logger-is-closed.md)
- [async-logger-is-running.md](./async-logger-is-running.md)
- [async-logger-has-failed.md](./async-logger-has-failed.md)
- [async-logger-last-error.md](./async-logger-last-error.md)
- [async-logger-flush-policy.md](./async-logger-flush-policy.md)
- [async-logger-state.md](./async-logger-state.md)
- [async-logger-state-to-json.md](./async-logger-state-to-json.md)
- [stringify-async-logger-state.md](./stringify-async-logger-state.md)
- [async-logger-close.md](./async-logger-close.md)
- [async-logger-wait-idle.md](./async-logger-wait-idle.md)
- [async-logger-shutdown.md](./async-logger-shutdown.md)

## Async runtime and config

- [async-runtime-mode.md](./async-runtime-mode.md)
- [async-runtime-mode-label.md](./async-runtime-mode-label.md)
- [async-runtime-supports-background-worker.md](./async-runtime-supports-background-worker.md)
- [async-runtime-state.md](./async-runtime-state.md)
- [async-runtime-state-to-json.md](./async-runtime-state-to-json.md)
- [stringify-async-runtime-state.md](./stringify-async-runtime-state.md)
- [async-logger-config.md](./async-logger-config.md)
- [async-logger-config-to-json.md](./async-logger-config-to-json.md)
- [stringify-async-logger-config.md](./stringify-async-logger-config.md)
- [parse-async-logger-build-config-text.md](./parse-async-logger-build-config-text.md)
- [build-async-logger.md](./build-async-logger.md)
- [async-logger-build-config-to-json.md](./async-logger-build-config-to-json.md)
- [stringify-async-logger-build-config.md](./stringify-async-logger-build-config.md)

## Configured logger runtime

- [configured-logger-flush.md](./configured-logger-flush.md)
- [configured-logger-drain.md](./configured-logger-drain.md)
- [configured-logger-close.md](./configured-logger-close.md)
- [configured-logger-pending-count.md](./configured-logger-pending-count.md)
- [configured-logger-dropped-count.md](./configured-logger-dropped-count.md)

## Configured logger file runtime

- [configured-logger-file-available.md](./configured-logger-file-available.md)
- [configured-logger-file-path.md](./configured-logger-file-path.md)
- [configured-logger-file-state.md](./configured-logger-file-state.md)
- [configured-logger-file-runtime-state.md](./configured-logger-file-runtime-state.md)
- [configured-logger-file-policy.md](./configured-logger-file-policy.md)
- [configured-logger-file-default-policy.md](./configured-logger-file-default-policy.md)
- [configured-logger-file-policy-matches-default.md](./configured-logger-file-policy-matches-default.md)
- [configured-logger-file-rotation-config.md](./configured-logger-file-rotation-config.md)
- [configured-logger-file-rotation-enabled.md](./configured-logger-file-rotation-enabled.md)
- [configured-logger-file-append-mode.md](./configured-logger-file-append-mode.md)
- [configured-logger-file-auto-flush.md](./configured-logger-file-auto-flush.md)
- [configured-logger-file-open-failures.md](./configured-logger-file-open-failures.md)
- [configured-logger-file-write-failures.md](./configured-logger-file-write-failures.md)
- [configured-logger-file-flush-failures.md](./configured-logger-file-flush-failures.md)
- [configured-logger-file-rotation-failures.md](./configured-logger-file-rotation-failures.md)

## Configured logger file control

- [configured-logger-file-flush.md](./configured-logger-file-flush.md)
- [configured-logger-file-close.md](./configured-logger-file-close.md)
- [configured-logger-file-reopen.md](./configured-logger-file-reopen.md)
- [configured-logger-file-reopen-append.md](./configured-logger-file-reopen-append.md)
- [configured-logger-file-reopen-truncate.md](./configured-logger-file-reopen-truncate.md)
- [configured-logger-file-reopen-with-current-policy.md](./configured-logger-file-reopen-with-current-policy.md)
- [configured-logger-file-set-policy.md](./configured-logger-file-set-policy.md)
- [configured-logger-file-reset-policy.md](./configured-logger-file-reset-policy.md)
- [configured-logger-file-set-rotation.md](./configured-logger-file-set-rotation.md)
- [configured-logger-file-clear-rotation.md](./configured-logger-file-clear-rotation.md)
- [configured-logger-file-set-append-mode.md](./configured-logger-file-set-append-mode.md)
- [configured-logger-file-set-auto-flush.md](./configured-logger-file-set-auto-flush.md)
- [configured-logger-file-reset-failure-counters.md](./configured-logger-file-reset-failure-counters.md)
