import DeviceActivity
import FamilyControls
import Flutter
import ManagedSettings
import SwiftUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "focusx/screen_time"
  private let activityCenter = DeviceActivityCenter()
  private var selectionController: UIViewController?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: channelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handle(call, result: result)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getCapabilities":
      result(capabilities())
    case "requestAuthorization":
      Task { @MainActor in
        do {
          try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
          UserDefaults.standard.removeObject(forKey: "focusx.authorizationFailure")
          result(["state": "supported"])
        } catch {
          let state = error.localizedDescription.localizedCaseInsensitiveContains("entitlement")
            ? "entitlementRequired" : "integrationError"
          UserDefaults.standard.set(state, forKey: "focusx.authorizationFailure")
          result(["state": state, "message": error.localizedDescription])
        }
      }
    case "selectApps":
      let arguments = call.arguments as? [String: Any] ?? [:]
      presentApplicationPicker(
        languageCode: arguments["languageCode"] as? String ?? "en",
        result: result
      )
    case "getAvailableApps":
      result(FlutterError(
        code: "unsupported",
        message: "iOS app identities are private; use the FamilyActivityPicker.",
        details: nil
      ))
    case "getSelectedApps":
      do {
        result(try selectedApps())
      } catch {
        result(FlutterError(
          code: "integration_error",
          message: error.localizedDescription,
          details: nil
        ))
      }
    case "getUsageSummary":
      result(FlutterError(
        code: "usage_summary_unavailable",
        message: "DeviceActivity threshold callbacks do not expose live per-app totals to Flutter.",
        details: nil
      ))
    case "configureAppLimit":
      do {
        result(try configureLimit(call.arguments as? [String: Any] ?? [:]))
      } catch {
        result(FlutterError(
          code: "integration_error",
          message: error.localizedDescription,
          details: nil
        ))
      }
    case "startDetoxSchedule", "stopDetoxSchedule":
      result(["state": "unsupported"])
    case "getIntegrationStatus":
      do {
        let arguments = call.arguments as? [String: Any] ?? [:]
        let status = try integrationStatus()
        try FocusXShared.saveLanguage(arguments["languageCode"] as? String ?? "en")
        result(status)
      } catch {
        result(FlutterError(
          code: "integration_error",
          message: error.localizedDescription,
          details: nil
        ))
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func presentApplicationPicker(
    languageCode: String,
    result: @escaping FlutterResult
  ) {
    guard AuthorizationCenter.shared.authorizationStatus == .approved else {
      result(FlutterError(
        code: authorizationState,
        message: "Authorize Family Controls before selecting apps.",
        details: nil
      ))
      return
    }
    guard let presenter = topViewController() else {
      result(FlutterError(
        code: "integration_error",
        message: "Unable to present the system app-selection interface.",
        details: nil
      ))
      return
    }

    let existingSelection: FamilyActivitySelection
    do {
      existingSelection = try FocusXShared.loadSelection()
    } catch {
      result(FlutterError(
        code: "integration_error",
        message: error.localizedDescription,
        details: nil
      ))
      return
    }
    let picker = FocusXSelectionView(
      selection: existingSelection,
      languageCode: languageCode
    ) { [weak self] selection in
      guard let self else { return }
      self.selectionController?.dismiss(animated: true)
      self.selectionController = nil
      guard let selection else {
        result(FlutterError(code: "selection_cancelled", message: "App selection was cancelled.", details: nil))
        return
      }
      do {
        try FocusXShared.saveLanguage(languageCode)
        try FocusXShared.saveSelection(selection)
        try self.reconcileSelection(selection.applicationTokens)
        try self.refreshMonitoring()
        result(try self.selectedApps())
      } catch {
        result(FlutterError(
          code: "integration_error",
          message: error.localizedDescription,
          details: nil
        ))
      }
    }
    let host = UIHostingController(rootView: picker)
    host.modalPresentationStyle = .formSheet
    selectionController = host
    presenter.present(host, animated: true)
  }

  private func topViewController() -> UIViewController? {
    let root = window?.rootViewController
      ?? UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows)
        .first(where: \.isKeyWindow)?
        .rootViewController
    var current = root
    while let presented = current?.presentedViewController {
      current = presented
    }
    return current
  }

  private func reconcileSelection(_ tokens: Set<ApplicationToken>) throws {
    var limits = try FocusXShared.loadLimits()
    var selectedIDs = Set<String>()
    for token in tokens {
      let id = try FocusXShared.tokenIdentifier(token)
      selectedIDs.insert(id)
      if limits[id] == nil {
        limits[id] = [
          "minutes": 30,
          "enabled": false,
          "resetHour": 0,
          "resetMinute": 0,
          "activityName": UUID().uuidString,
        ]
      }
    }
    let removedIDs = limits.keys.filter { !selectedIDs.contains($0) }
    for id in removedIDs {
      if let token = FocusXShared.applicationToken(for: id) {
        FocusXShared.clearBlockedState(for: id, token: token)
      }
      limits.removeValue(forKey: id)
    }
    try FocusXShared.saveLimits(limits)
  }

  private func configureLimit(_ arguments: [String: Any]) throws -> [String: String] {
    guard AuthorizationCenter.shared.authorizationStatus == .approved else {
      return ["state": authorizationState]
    }
    guard FocusXShared.sharedStorageAvailable else {
      throw NSError(
        domain: "FocusX",
        code: 10,
        userInfo: [NSLocalizedDescriptionKey: "The shared App Group container is unavailable."]
      )
    }
    guard
      let id = arguments["appId"] as? String,
      let minutes = arguments["dailyLimitMinutes"] as? Int,
      (1...1440).contains(minutes),
      let enabled = arguments["enabled"] as? Bool,
      let hour = arguments["resetHour"] as? Int,
      (0...23).contains(hour),
      let minute = arguments["resetMinute"] as? Int,
      (0...59).contains(minute)
    else {
      throw NSError(
        domain: "FocusX",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Invalid app limit configuration."]
      )
    }
    if enabled && !requiredExtensionsAreEmbedded {
      throw NSError(
        domain: "FocusX",
        code: 5,
        userInfo: [NSLocalizedDescriptionKey: "Required Screen Time extensions are missing from this build."]
      )
    }
    try FocusXShared.saveLanguage(arguments["languageCode"] as? String ?? "en")
    guard let token = FocusXShared.applicationToken(for: id) else {
      throw NSError(
        domain: "FocusX",
        code: 2,
        userInfo: [NSLocalizedDescriptionKey: "The selected app token is no longer available."]
      )
    }

    var limits = try FocusXShared.loadLimits()
    let previous = limits[id]
    let unchanged = previous?["minutes"] as? Int == minutes
      && previous?["enabled"] as? Bool == enabled
      && previous?["resetHour"] as? Int == hour
      && previous?["resetMinute"] as? Int == minute
    let activityName = unchanged
      ? (previous?["activityName"] as? String ?? UUID().uuidString)
      : UUID().uuidString
    limits[id] = [
      "minutes": minutes,
      "enabled": enabled,
      "resetHour": hour,
      "resetMinute": minute,
      "activityName": activityName,
    ]
    try FocusXShared.saveLimits(limits)
    if !enabled || !unchanged {
      FocusXShared.clearBlockedState(for: id, token: token)
    }

    try refreshMonitoring()
    guard !enabled || activityCenter.activities.contains(
      DeviceActivityName("focusx.\(activityName)")
    ) else {
      throw NSError(
        domain: "FocusX",
        code: 3,
        userInfo: [NSLocalizedDescriptionKey: "DeviceActivity did not register the daily monitor."]
      )
    }
    return ["state": enabled ? "activeMonitoring" : "supported"]
  }

  private func refreshMonitoring() throws {
    let limits = try FocusXShared.loadLimits()
    let desiredNames = Set(
      limits.values.compactMap { record -> String? in
        guard record["enabled"] as? Bool == true,
              let name = record["activityName"] as? String else { return nil }
        return "focusx.\(name)"
      }
    )
    let existingNames = activityCenter.activities.filter {
      $0.rawValue.hasPrefix("focusx.")
    }
    let namesToStop = existingNames.filter { !desiredNames.contains($0.rawValue) }
    if !namesToStop.isEmpty {
      activityCenter.stopMonitoring(namesToStop)
    }

    for (id, record) in limits where record["enabled"] as? Bool == true {
      guard
        let token = FocusXShared.applicationToken(for: id),
        let minutes = record["minutes"] as? Int,
        let hour = record["resetHour"] as? Int,
        let minute = record["resetMinute"] as? Int,
        let activityID = record["activityName"] as? String
      else {
        throw NSError(
          domain: "FocusX",
          code: 4,
          userInfo: [NSLocalizedDescriptionKey: "A saved app selection could not be decoded."]
        )
      }
      let name = DeviceActivityName("focusx.\(activityID)")
      if activityCenter.activities.contains(name) {
        continue
      }
      let (endHour, endMinute) = previousMinute(hour: hour, minute: minute)
      let schedule = DeviceActivitySchedule(
        intervalStart: DateComponents(hour: hour, minute: minute),
        intervalEnd: DateComponents(hour: endHour, minute: endMinute),
        repeats: true
      )
      let event = DeviceActivityEvent(
        applications: [token],
        threshold: DateComponents(hour: minutes / 60, minute: minutes % 60),
        includesPastActivity: true
      )
      try activityCenter.startMonitoring(
        name,
        during: schedule,
        events: [DeviceActivityEvent.Name("limitReached"): event]
      )
    }
  }

  private func previousMinute(hour: Int, minute: Int) -> (Int, Int) {
    if minute > 0 { return (hour, minute - 1) }
    return ((hour + 23) % 24, 59)
  }

  private func selectedApps() throws -> [String: Any] {
    guard FocusXShared.sharedStorageAvailable else {
      throw NSError(
        domain: "FocusX",
        code: 10,
        userInfo: [NSLocalizedDescriptionKey: "The shared App Group container is unavailable."]
      )
    }
    let selection = try FocusXShared.loadSelection()
    let tokens = try selection.applicationTokens
      .map { token -> (String, ApplicationToken) in
        (try FocusXShared.tokenIdentifier(token), token)
      }
      .sorted { $0.0 < $1.0 }
    let limits = try FocusXShared.loadLimits()
    let store = FocusXShared.store
    let blockedTokens = store.shield.applications ?? []
    let monitoredNames = activityCenter.activities.map(\.rawValue)
    let reachedIDs = FocusXShared.loadReachedIDs()
    let apps: [[String: Any]] = try tokens.enumerated().map { index, item in
      let (id, token) = item
      let record = limits[id] ?? [:]
      let enabled = record["enabled"] as? Bool ?? false
      let activityName = record["activityName"] as? String ?? ""
      let state: String
      if blockedTokens.contains(token) {
        state = "appBlocked"
      } else if reachedIDs.contains(id) {
        state = "limitReached"
      } else if FocusXShared.hasIntegrationError(for: id) {
        state = "integrationError"
      } else if enabled && monitoredNames.contains("focusx.\(activityName)") {
        state = "activeMonitoring"
      } else if enabled || !requiredExtensionsAreEmbedded {
        state = "integrationError"
      } else {
        state = "supported"
      }
      return [
        "id": id,
        "name": "Selected app \(index + 1)",
        "dailyLimitMinutes": record["minutes"] as? Int ?? 30,
        "enabled": enabled,
        "usedMinutes": NSNull(),
        "remainingMinutes": NSNull(),
        "resetHour": record["resetHour"] as? Int ?? 0,
        "resetMinute": record["resetMinute"] as? Int ?? 0,
        "state": state,
      ]
    }
    return ["apps": apps]
  }

  private func capabilities() -> [String: Any] {
    let authorization = authorizationState
    let monitoringState: String
    if authorization != "supported" {
      monitoringState = authorization
    } else if !FocusXShared.sharedStorageAvailable || !requiredExtensionsAreEmbedded {
      monitoringState = "integrationError"
    } else {
      monitoringState = "supported"
    }
    return [
      "platform": "iOS",
      "authorization": authorization,
      "capabilities": [
        capability("usageAccess", "unsupported"),
        capability("appSelection", authorization),
        capability("appBlocking", monitoringState),
        capability("backgroundMonitoring", monitoringState),
      ],
    ]
  }

  private func integrationStatus() throws -> [String: Any] {
    if AuthorizationCenter.shared.authorizationStatus == .denied {
      let focusXActivities = activityCenter.activities.filter {
        $0.rawValue.hasPrefix("focusx.")
      }
      if !focusXActivities.isEmpty {
        activityCenter.stopMonitoring(focusXActivities)
      }
      FocusXShared.store.clearAllSettings()
      try FocusXShared.clearSelections()
    }
    var values = capabilities()
    values["apps"] = try selectedApps()["apps"]
    if authorizationState == "supported" {
      values["message"] = requiredExtensionsAreEmbedded
        ? "Live app usage totals are not exposed by the threshold monitor; device shields are applied by the DeviceActivity extension."
        : "Screen Time extension targets are not embedded. App limits cannot run until the iOS targets and entitlements are configured."
    } else {
      values["message"] = "Family Controls authorization is required. Distribution also requires Apple's Family Controls entitlement approval."
    }
    return values
  }

  private var authorizationState: String {
    switch AuthorizationCenter.shared.authorizationStatus {
    case .approved: return "supported"
    case .denied:
      return UserDefaults.standard.string(forKey: "focusx.authorizationFailure")
        ?? "permissionRequired"
    case .notDetermined: return "permissionRequired"
    @unknown default: return "integrationError"
    }
  }

  private var requiredExtensionsAreEmbedded: Bool {
    guard
      let pluginsURL = Bundle.main.builtInPlugInsURL,
      let urls = try? FileManager.default.contentsOfDirectory(
        at: pluginsURL,
        includingPropertiesForKeys: nil
      )
    else {
      return false
    }
    let identifiers = Set(urls.compactMap { Bundle(url: $0)?.bundleIdentifier })
    return [
      "com.focusx.focusx.DeviceActivityMonitor",
      "com.focusx.focusx.ShieldConfiguration",
      "com.focusx.focusx.ShieldAction",
    ].isSubset(of: identifiers)
  }

  private func capability(_ name: String, _ state: String) -> [String: String] {
    ["name": name, "state": state]
  }
}

private struct FocusXSelectionView: View {
  @State private var selection: FamilyActivitySelection
  @State private var pickerPresented = false
  let languageCode: String
  let onComplete: (FamilyActivitySelection?) -> Void

  init(
    selection: FamilyActivitySelection,
    languageCode: String,
    onComplete: @escaping (FamilyActivitySelection?) -> Void
  ) {
    _selection = State(initialValue: selection)
    self.languageCode = languageCode
    self.onComplete = onComplete
  }

  private var isArabic: Bool { languageCode == "ar" }

  var body: some View {
    NavigationStack {
      VStack(spacing: 18) {
        Image(systemName: "hand.raised.fingers.spread.fill")
          .font(.system(size: 38))
          .foregroundStyle(Color(red: 0.72, green: 1.0, blue: 0.36))
        Text(isArabic ? "اختر التطبيقات لوضع حد يومي" : "Choose individual apps to limit")
          .font(.headline)
        Text(
          isArabic
            ? "يحافظ iOS على خصوصية أسماء التطبيقات داخل أداة النظام. حدود الفئات والمواقع غير مفعّلة هنا."
            : "iOS keeps selected app identities private to this system picker. App categories and websites are not applied by this per-app limit."
        )
          .font(.subheadline)
          .multilineTextAlignment(.center)
          .foregroundStyle(.secondary)
        Button(isArabic ? "فتح أداة اختيار التطبيقات" : "Open app picker") {
          pickerPresented = true
        }
        .buttonStyle(.borderedProminent)
        Text(
          isArabic
            ? "التطبيقات المحددة: \(selection.applicationTokens.count)"
            : "\(selection.applicationTokens.count) apps selected"
        )
          .font(.footnote)
          .foregroundStyle(.secondary)
        Spacer()
      }
      .padding(24)
      .navigationTitle("FOCUSX")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(isArabic ? "إلغاء" : "Cancel") { onComplete(nil) }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(isArabic ? "حفظ" : "Save") { onComplete(selection) }
            .disabled(!selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty)
        }
      }
      .familyActivityPicker(isPresented: $pickerPresented, selection: $selection)
    }
    .environment(\.layoutDirection, isArabic ? .rightToLeft : .leftToRight)
  }
}
