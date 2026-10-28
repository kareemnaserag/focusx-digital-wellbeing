import FamilyControls
import Foundation
import ManagedSettings

enum FocusXShared {
  static let appGroup = "group.com.focusx.focusx"
  static let selectionKey = "familyActivitySelection"
  static let limitsKey = "appLimits"
  static let reachedKey = "reachedAppIDs"
  static let integrationErrorsKey = "integrationErrors"
  static let languageKey = "languageCode"
  static let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("focusx"))

  static var defaults: UserDefaults? {
    UserDefaults(suiteName: appGroup)
  }

  static var sharedStorageAvailable: Bool {
    defaults != nil
  }

  static func loadSelection() throws -> FamilyActivitySelection {
    guard let defaults else {
      throw NSError(
        domain: "FocusX",
        code: 10,
        userInfo: [NSLocalizedDescriptionKey: "The shared App Group container is unavailable."]
      )
    }
    guard let data = defaults.data(forKey: selectionKey) else {
      return FamilyActivitySelection()
    }
    do {
      return try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    } catch {
      throw NSError(
        domain: "FocusX",
        code: 11,
        userInfo: [NSLocalizedDescriptionKey: "The saved Screen Time selection could not be decoded."]
      )
    }
  }

  static func saveSelection(_ selection: FamilyActivitySelection) throws {
    let data = try JSONEncoder().encode(selection)
    guard let defaults else {
      throw NSError(
        domain: "FocusX",
        code: 10,
        userInfo: [NSLocalizedDescriptionKey: "The shared App Group container is unavailable."]
      )
    }
    defaults.set(data, forKey: selectionKey)
  }

  static func tokenIdentifier(_ token: ApplicationToken) throws -> String {
    try JSONEncoder().encode(token).base64EncodedString()
  }

  static func applicationToken(for identifier: String) -> ApplicationToken? {
    guard let data = Data(base64Encoded: identifier) else { return nil }
    return try? JSONDecoder().decode(ApplicationToken.self, from: data)
  }

  static func loadLimits() throws -> [String: [String: Any]] {
    guard let defaults else {
      throw NSError(
        domain: "FocusX",
        code: 10,
        userInfo: [NSLocalizedDescriptionKey: "The shared App Group container is unavailable."]
      )
    }
    guard let stored = defaults.dictionary(forKey: limitsKey) else {
      if defaults.object(forKey: limitsKey) == nil { return [:] }
      throw NSError(
        domain: "FocusX",
        code: 12,
        userInfo: [NSLocalizedDescriptionKey: "Saved Screen Time limits are invalid."]
      )
    }
    guard let limits = stored as? [String: [String: Any]] else {
      throw NSError(
        domain: "FocusX",
        code: 12,
        userInfo: [NSLocalizedDescriptionKey: "Saved Screen Time limits are invalid."]
      )
    }
    return limits
  }

  static func saveLimits(_ limits: [String: [String: Any]]) throws {
    guard let defaults else {
      throw NSError(
        domain: "FocusX",
        code: 10,
        userInfo: [NSLocalizedDescriptionKey: "The shared App Group container is unavailable."]
      )
    }
    defaults.set(limits, forKey: limitsKey)
  }

  static func clearSelections() throws {
    guard let defaults else {
      throw NSError(
        domain: "FocusX",
        code: 10,
        userInfo: [NSLocalizedDescriptionKey: "The shared App Group container is unavailable."]
      )
    }
    defaults.removeObject(forKey: selectionKey)
    defaults.removeObject(forKey: limitsKey)
    defaults.removeObject(forKey: reachedKey)
    defaults.removeObject(forKey: integrationErrorsKey)
  }

  static func saveLanguage(_ languageCode: String) throws {
    guard let defaults else {
      throw NSError(
        domain: "FocusX",
        code: 10,
        userInfo: [NSLocalizedDescriptionKey: "The shared App Group container is unavailable."]
      )
    }
    defaults.set(languageCode == "ar" ? "ar" : "en", forKey: languageKey)
  }

  static func loadReachedIDs() -> Set<String> {
    Set(defaults?.stringArray(forKey: reachedKey) ?? [])
  }

  static func setReached(_ isReached: Bool, for identifier: String) {
    var values = loadReachedIDs()
    if isReached {
      values.insert(identifier)
    } else {
      values.remove(identifier)
    }
    defaults?.set(Array(values), forKey: reachedKey)
  }

  static func clearBlockedState(for identifier: String, token: ApplicationToken) {
    var blocked = store.shield.applications ?? []
    blocked.remove(token)
    store.shield.applications = blocked.isEmpty ? nil : blocked
    setReached(false, for: identifier)
  }

  static func clearIntegrationError(for identifier: String) {
    var errors = Set(defaults?.stringArray(forKey: integrationErrorsKey) ?? [])
    errors.remove(identifier)
    defaults?.set(Array(errors), forKey: integrationErrorsKey)
  }

  static func setIntegrationError(for identifier: String) {
    var errors = Set(defaults?.stringArray(forKey: integrationErrorsKey) ?? [])
    errors.insert(identifier)
    defaults?.set(Array(errors), forKey: integrationErrorsKey)
  }

  static func hasIntegrationError(for identifier: String) -> Bool {
    (defaults?.stringArray(forKey: integrationErrorsKey) ?? []).contains(identifier)
  }
}
