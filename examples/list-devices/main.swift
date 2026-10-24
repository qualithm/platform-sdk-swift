// List the devices in the token's team.
//
//   QUALITHM_API_TOKEN=qmt_... swift run list-devices

import Foundation
import QualithmPlatform

do {
  let platform = try PlatformClient()

  // An API token belongs to one team, so its team list has exactly that team.
  let teams = try await platform.call { try await TeamsAPI.listTeams(apiConfiguration: $0) }
  guard let team = teams.data.items.first else {
    FileHandle.standardError.write(Data("list-devices: the token has no team\n".utf8))
    exit(1)
  }

  let page = try await platform.call {
    try await DevicesAPI.listDevices(teamId: team.id, limit: 20, apiConfiguration: $0)
  }
  for device in page.data.items {
    print("\(device.id)  \(device.spaceName)  \(device.name)")
  }
} catch {
  FileHandle.standardError.write(
    Data("list-devices: \(error.message) (\(error.code.rawValue))\n".utf8))
  exit(1)
}
