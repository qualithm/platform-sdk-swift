# Swift Code Guidelines

`swift format` (config in `.swift-format`) enforces formatting, import order, documentation on
public declarations and the ban on force unwraps and `try!`. Fix what it flags; this file covers
what it can't.

## Layout

- A SwiftPM package: library code in `Sources/<Module>/`, tests in `Tests/<Module>Tests/`, runnable
  examples as executable targets under `examples/`. One type per file, named after it.
- Swift 6 language mode with strict concurrency. Public types are `Sendable` where they can be;
  never silence a concurrency diagnostic with `@unchecked Sendable` or `nonisolated(unsafe)` without
  a comment saying why it's safe.
- The package builds on Linux as well as Apple platforms: CI tests it there. Import Foundation, not
  Apple-only frameworks; guard any platform code with `#if canImport(...)` and keep it out of the
  logic the tests exercise.

## API

- Follow the Swift API Design Guidelines: clarity at the point of use, argument labels that read as
  a phrase, no abbreviations. Options go in a struct with defaulted `init` parameters.
- Errors are an `enum` conforming to `Error` per module (`{Component}Error`), thrown with typed
  `throws(...)` from public API so callers can switch exhaustively. No `fatalError` or
  `precondition` on input a caller controls.
- Every public declaration has a `///` comment: one summary line, then `- Parameters:`, `- Returns:`
  and `- Throws:` as they apply. No architecture overviews or feature lists in comments.
- Prefer value types and `let`. Reach for a class only for identity or shared mutable state, and
  make it `final`.

## Tests

- XCTest, one `XCTestCase` per type under test, test names that state the behaviour
  (`testRejectsBlankName`). Assert thrown errors with `XCTAssertThrowsError` and check the case.
- A behaviour change carries tests that cover its new lines (`dx coverage patch` checks them after
  the coverage step).

## Dependencies

Pin each dependency with `exact:` or `from:` in `Package.swift` and commit `Package.resolved`, so CI
and the daily audit see the versions you built with. Drop dependencies nothing uses.

## Generated files

`.github/workflows/ci.yaml` is generated from `dx/ci-templates/`; change the template and run
`dx ci sync` from dx, never edit it here. `CI Required` is the single required status check.
