import ManagedSettings
import ManagedSettingsUI
import UIKit

final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
  override func configuration(shielding application: Application) -> ShieldConfiguration {
    let languageCode = UserDefaults(suiteName: "group.com.focusx.focusx")?
      .string(forKey: "languageCode")
    let isArabic = languageCode == "ar"
    return ShieldConfiguration(
      backgroundBlurStyle: .systemMaterialDark,
      backgroundColor: UIColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 1),
      icon: UIImage(systemName: "hourglass"),
      title: ShieldConfiguration.Label(
        text: isArabic
          ? "انتهى الحد اليومي"
          : NSLocalizedString("limit_title", comment: ""),
        color: UIColor(red: 0.72, green: 1.0, blue: 0.36, alpha: 1)
      ),
      subtitle: ShieldConfiguration.Label(
        text: isArabic
          ? "انتهى الوقت المحدد لهذا التطبيق. سيُعاد ضبط الحد في الموعد المحدد."
          : NSLocalizedString("limit_message", comment: ""),
        color: .white
      ),
      primaryButtonLabel: ShieldConfiguration.Label(
        text: isArabic ? "إغلاق" : NSLocalizedString("close_button", comment: ""),
        color: .black
      ),
      primaryButtonBackgroundColor: UIColor(red: 0.72, green: 1.0, blue: 0.36, alpha: 1)
    )
  }
}
