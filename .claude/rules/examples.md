---
description: "Conventions for runnable example targets"
paths:
  - "examples/**"
---

# Example Conventions

## File Structure

Each example is an executable target in `Package.swift` whose sources are
`examples/<example-name>/main.swift`:

```swift
.executableTarget(name: "basic-usage", dependencies: ["Example"], path: "examples/basic-usage"),
```

1. A header comment: one line saying what the example shows, then how to run it
   (`//     swift run basic-usage`)
2. Imports, the package's module last
3. Helper types and functions, each with a `///` comment
4. Top-level code in `main.swift` as the entry point; `try` at top level is fine

## Conventions

- Use the public API only: no `@testable import`.
- Print what happens, so running the example shows the behaviour.
- Handle the errors the example is about with `do`/`catch` and a `switch` over the error's cases;
  let any other error end the run.
- The examples are outside the coverage gate, but CI builds them with `swift build`.

## Running Examples

```bash
swift run EXAMPLE_NAME
```

## README

`examples/README.md` has:

1. `# Examples` heading
2. A one-line intro
3. An `| Example | Description |` table linking each `main.swift`
4. The `swift run` command
