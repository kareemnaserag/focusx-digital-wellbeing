import ManagedSettings
import ManagedSettingsUI

final class ShieldActionExtension: ShieldActionDelegate {
  override func handle(
    action: ShieldAction,
    for application: ApplicationToken,
    completionHandler: @escaping (ShieldActionResponse) -> Void
  ) {
    switch action {
    case .primaryButtonPressed:
      completionHandler(.close)
    case .secondaryButtonPressed:
      completionHandler(.defer)
    @unknown default:
      completionHandler(.close)
    }
  }
}
