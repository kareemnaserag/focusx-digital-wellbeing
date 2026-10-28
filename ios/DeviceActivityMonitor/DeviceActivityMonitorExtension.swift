import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import os

final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
  private let logger = Logger(subsystem: "com.focusx.focusx", category: "DeviceActivity")

  override func intervalDidStart(for activity: DeviceActivityName) {
    super.intervalDidStart(for: activity)
    guard let (identifier, token) = record(for: activity) else { return }
    FocusXShared.clearBlockedState(for: identifier, token: token)
    FocusXShared.clearIntegrationError(for: identifier)
  }

  override func eventDidReachThreshold(
    _ event: DeviceActivityEvent.Name,
    for activity: DeviceActivityName
  ) {
    super.eventDidReachThreshold(event, for: activity)
    guard event == DeviceActivityEvent.Name("limitReached"),
          let (identifier, token) = record(for: activity) else { return }

    FocusXShared.setReached(true, for: identifier)
    let current = FocusXShared.store.shield.applications ?? []
    FocusXShared.store.shield.applications = current.union([token])
    let applied = FocusXShared.store.shield.applications?.contains(token) == true
    if applied {
      FocusXShared.clearIntegrationError(for: identifier)
    } else {
      FocusXShared.setIntegrationError(for: identifier)
    }
  }

  private func record(
    for activity: DeviceActivityName
  ) -> (String, ApplicationToken)? {
    let activityID = activity.rawValue.replacingOccurrences(of: "focusx.", with: "")
    let limits: [String: [String: Any]]
    do {
      limits = try FocusXShared.loadLimits()
    } catch {
      logger.error("Unable to load persisted limit configuration: \(error.localizedDescription)")
      return nil
    }
    guard let record = limits.first(where: {
      $0.value["activityName"] as? String == activityID
    }) else { return nil }
    guard let token = FocusXShared.applicationToken(for: record.key) else {
      FocusXShared.setIntegrationError(for: record.key)
      return nil
    }
    return (record.key, token)
  }
}
