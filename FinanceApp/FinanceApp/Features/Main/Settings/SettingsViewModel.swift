//
//  SettingsViewModel.swift
//  FinanceApp
//
//  Created by Macbook on 2.28.26.
//

import UIKit
import Combine
import UserNotifications

private enum SettingsKeys {
    static let darkMode = "Settings.darkMode"
    static let pushNotificationsEnabled = "Settings.pushNotificationsEnabled"
}

final class SettingsViewModel: ObservableObject {

    @Published private(set) var darkModeOn: Bool {
        didSet {
            UserDefaults.standard.set(darkModeOn, forKey: SettingsKeys.darkMode)
        }
    }

    @Published private(set) var pushNotificationsOn: Bool {
        didSet {
            UserDefaults.standard.set(pushNotificationsOn, forKey: SettingsKeys.pushNotificationsEnabled)
        }
    }
 
    let languageDisplay: String = "Azərbaycan"

    init() {
        self.darkModeOn = UserDefaults.standard.object(forKey: SettingsKeys.darkMode) as? Bool ?? false
        self.pushNotificationsOn = UserDefaults.standard.object(forKey: SettingsKeys.pushNotificationsEnabled) as? Bool ?? false
    }
 
    func setDarkMode(_ on: Bool, window: UIWindow?) {
        darkModeOn = on
        applyAppearance(to: window)
    }
 
    func applyAppearance(to window: UIWindow?) {
        window?.overrideUserInterfaceStyle = darkModeOn ? .dark : .light
    }
 
    func setPushNotifications(_ on: Bool, completion: @escaping (Bool) -> Void) {
        if on {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.pushNotificationsOn = granted
                    if granted {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                    completion(granted)
                }
            }
        } else {
            pushNotificationsOn = false
            completion(true)
        }
    }
 
    static func applySavedAppearance(to window: UIWindow?) {
        let on = UserDefaults.standard.object(forKey: SettingsKeys.darkMode) as? Bool ?? false
        window?.overrideUserInterfaceStyle = on ? .dark : .light
    }
 
    func scheduleTestNotification(completion: @escaping (Bool, String?) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                guard settings.authorizationStatus == .authorized else {
                    completion(false, "Turn on notifications in Settings first, then try again.")
                    return
                }
                let content = UNMutableNotificationContent()
                content.title = "Test"
                content.body = "Push notifications are working."
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: "test-\(UUID().uuidString)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request) { error in
                    DispatchQueue.main.async {
                        if error != nil {
                            completion(false, error?.localizedDescription)
                        } else {
                            completion(true, "Notification in 5 seconds. Send app to background to see it.")
                        }
                    }
                }
            }
        }
    }
}
