---
description: "Runtime conventions for errors, logs, settings and CLIs"
paths:
  - "**/*.swift"
---

# Runtime Conventions

One set of rules for errors, logs, settings and CLIs holds in every language, so logs and errors
from different repos read and search together. This is how they look here.

## Errors

- Errors are a `{Component}Error` enum thrown with typed `throws(...)`. Messages are lowercase, with
  no trailing punctuation, and name what failed (`claim code expired`).

## Logging

- Library code never prints. Where it logs, it takes a logger from the caller.
- A log line is a `snake_case` event plus fields, never a sentence with values interpolated.
- Field keys are `snake_case` in every language, so one query reads every service. The shared names
  are `team_id`, `device_id`, `request_id`, `trace_id`, `duration_ms`, and `error` for the error,
  never `e` or `err`.

## Settings

- Options are a `{Component}Config` struct with production defaults, and units go in names
  (`timeoutMs`, `maxBodyBytes`).
- Env vars it reads for its own settings start with `QUALITHM_`, because it runs on a builder's
  machine or device. Standard names (`PORT`, `LOG_LEVEL`) stay unprefixed, and credentials keep
  their own naming rule.
