# Platform SDK Swift

[![CI](https://github.com/qualithm/platform-sdk-swift/actions/workflows/ci.yaml/badge.svg)](https://github.com/qualithm/platform-sdk-swift/actions/workflows/ci.yaml)
[![codecov](https://codecov.io/gh/qualithm/platform-sdk-swift/graph/badge.svg)](https://codecov.io/gh/qualithm/platform-sdk-swift)

Swift client for the Qualithm Platform API, generated from its OpenAPI spec. Every operation and
type comes from the spec the API serves, so the client changes when the API does.

## Features

- **Every management operation** — one typed `async` call per operation, grouped by resource
  (`DevicesAPI`, `AutomationsAPI`, …), with the spec's names
- **One error type** — every failure is a `PlatformError` carrying the API's stable `code`
- **Configured from the environment** — `QUALITHM_API_TOKEN` and `QUALITHM_API_URL`
- **No dependencies** — Foundation's `URLSession` only

## Installation

Add the package to `Package.swift`:

```swift
.package(url: "https://github.com/qualithm/platform-sdk-swift", from: "0.2.0"),
```

Then depend on the `QualithmPlatform` product:

```swift
.target(name: "App", dependencies: [.product(name: "QualithmPlatform", package: "platform-sdk-swift")]),
```

## Quick Start

Create an API token in the Qualithm app, on the team page under **API tokens**, then:

```swift
import QualithmPlatform

let platform = try PlatformClient(token: "<your-api-token>")

// An API token belongs to one team, so its team list has exactly that team.
let teams = try await platform.call { try await TeamsAPI.listTeams(apiConfiguration: $0) }
let teamId = teams.data.items[0].id

let page = try await platform.call {
  try await DevicesAPI.listDevices(teamId: teamId, apiConfiguration: $0)
}

for device in page.data.items {
  print(device.name)
}
```

## Usage

### Configure the client

`PlatformClient` reads `QUALITHM_API_TOKEN` and `QUALITHM_API_URL` when you don't pass `token` or
`baseURL`. The base URL defaults to the production API, `https://api.qualithm.com`.

```swift
let platform = try PlatformClient(baseURL: "https://api.qualithm.com")
```

### Call an operation

Each generated `…API` type is one resource group. Run its calls through `platform.call`, which
passes your configuration as `$0`. Method names match the spec's `operationId`s. Every response is
the API's envelope, so the result is in `data`. Operations on a team's resources take its `teamId`:

```swift
let automations = try await platform.call {
  try await AutomationsAPI.listAutomations(teamId: teamId, page: 1, limit: 50, apiConfiguration: $0)
}
```

### Error Handling

`platform.call` throws only `PlatformError`. Branch on `code`, never on `message`. A code this
version doesn't know yet reads as `.unknownDefaultOpenApi`, and a request that got no response is
`.transport`:

```swift
do {
  _ = try await platform.call {
    try await DevicesAPI.getDevice(teamId: teamId, deviceId: id, apiConfiguration: $0)
  }
} catch where error.code == .notFound {
  // the device doesn't exist, or isn't in this team
}
```

## API Reference

The operations and types are generated from the platform's OpenAPI spec, committed as
[`openapi.json`](openapi.json). Build the documentation with DocC:

```bash
swift package generate-documentation --target QualithmPlatform
```

## Examples

| Example                                            | Description                                                        |
| -------------------------------------------------- | ------------------------------------------------------------------ |
| [`list-devices`](examples/list-devices/main.swift) | List the devices in the token's team, and report a `PlatformError` |

```bash
QUALITHM_API_TOKEN=<your-api-token> swift run list-devices
```

## Development

### Prerequisites

- Swift 6.4 (Xcode 27 on macOS)
- [Docker](https://www.docker.com/), to regenerate the client

### Regenerating

`Sources/QualithmPlatform/Generated/` comes from `openapi.json` and the generator pinned in
`scripts/generate`. Never edit it by hand: CI regenerates it and fails on any difference. The
platform opens a pull request here with the new spec and the regenerated code whenever its API
changes. To regenerate by hand:

```bash
scripts/generate
```

The hand-written layer is `PlatformClient.swift` and `PlatformError.swift`.

### Checks

```bash
git ls-files -z '*.swift' | xargs -0 swift format lint --strict
swift build
swift test
```

## Supported Platforms

macOS 15, iOS 18 and Linux, with Swift 6.4.

## License

Apache-2.0
