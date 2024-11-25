import Foundation
import UserNotifications
import SwiftUI
import CoreData

extension Notification.Name {
    static let openClientDetail = Notification.Name("openClientDetail")
}

/// Gestionnaire des interactions utilisateur avec les notifications
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate() // Singleton

    // Affiche les notifications lorsque l'application est au premier plan
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    // Gère les actions lorsque l'utilisateur clique sur une notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo

        // Gérer les redirections selon les données associées à la notification
        if let clientID = userInfo["clientID"] as? String {
            NotificationCenter.default.post(name: .openClientDetail, object: clientID)
        } else {
            NotificationCenter.default.post(name: .refreshClients, object: nil)
        }

        completionHandler()
    }
}
