---
description: "Exact pre-commit commands for the swift-lib CI archetype, kept in sync with ci.yaml"
---

# Pre-commit Checks

This repo's `ci.yaml` is generated from `dx/ci-templates/swift-lib.yaml` via `dx ci sync` (check for
drift with `dx ci drift`). Run these before committing so CI passes on the first try:

```bash
git ls-files -z '*.swift' | xargs -0 swift format lint --strict   # `git ls-files -z '*.swift' | xargs -0 swift format --in-place` rewrites the files
swift build
python3 .claude/checks/ci-jobs.py --skip-ci-only coverage
```

Run them with full Xcode selected (`xcode-select -s`): the Command Line Tools alone have no XCTest.
CI's macOS job uses the Xcode the template pins (`XCODE_VERSION` in `ci.yaml`) at
`/Applications/Xcode_<version>.app`; `dx brew pinned` sets it up. `swift format` ships with that
toolchain; `.swift-format` is its config.

The `ci-jobs.py --skip-ci-only coverage` step runs CI's coverage job locally: the same tests and the
same 80% line gate over `Sources/`, minus the Codecov upload. Tests and `examples/` are outside the
gate.

CI runs the lint and coverage jobs on Linux, in the `swift` image of the pinned version. Code that
builds on macOS can still fail there: Foundation on Linux lacks some Apple-only API, and anything
importing an Apple framework (`Combine`, `CryptoKit`, `os`) must sit behind `#if canImport(...)`.
Check with the same image when you touch platform code:

```bash
docker run --rm -v "$PWD":/src -w /src swift:<SWIFT_VERSION>-noble swift test
```

On PRs targeting `main`, CI also builds and tests on macOS with the pinned Xcode.
