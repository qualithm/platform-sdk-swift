// List the workspace's devices.
//
//   QUALITHM_API_TOKEN=qmt_... swift run list-devices

import Foundation
import QualithmPlatform

do {
  let platform = try PlatformClient()
  let page = try await platform.call {
    try await DevicesAPI.listDevices(limit: 20, apiConfiguration: $0)
  }
  for device in page.data.items {
    print("\(device.id)  \(device.spaceName)  \(device.name)")
  }
} catch {
  FileHandle.standardError.write(
    Data("list-devices: \(error.message) (\(error.code.rawValue))\n".utf8))
  exit(1)
}
