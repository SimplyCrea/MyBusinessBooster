import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    // Variable partagée pour stocker l'ID du client à ouvrir
    static var pendingClientID: String?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Vérifiez si l'application est lancée via une notification
        if let userInfo = launchOptions?[.remoteNotification] as? [String: Any] {
            if let clientID = userInfo["clientID"] as? String {
                print("🚀 Application lancée avec client ID : \(clientID)")
                AppDelegate.pendingClientID = clientID
            } else {
                print("⚠️ Lancement via notification, mais aucun clientID trouvé.")
            }
        }
        
        // Configuration des catégories de notifications
        setupNotificationCategories()

        // Définir le délégué des notifications
        UNUserNotificationCenter.current().delegate = self

        // Demander l'autorisation des notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Erreur lors de la demande d'autorisation : \(error.localizedDescription)")
            } else if granted {
                print("✅ Notifications autorisées avec alertes, badges et sons.")
            } else {
                print("❌ Notifications refusées.")
            }
        }

        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("🔔 Notification cliquée : \(userInfo)")

        if let clientID = userInfo["clientID"] as? String {
            print("📂 Client ID reçu : \(clientID)")
            AppDelegate.pendingClientID = clientID

            // Postez une notification pour naviguer immédiatement si l'application est active
            NotificationCenter.default.post(name: .openClientDetail, object: clientID)
        } else {
            print("⚠️ Aucune clé 'clientID' trouvée dans la notification.")
        }

        // Réinitialisez le badge de l'application
        UIApplication.shared.applicationIconBadgeNumber = 0
        print("📛 Badge réinitialisé après interaction avec la notification.")

        completionHandler()
    }

    /// Configure les catégories de notifications
    private func setupNotificationCategories() {
        let clientReminderCategory = UNNotificationCategory(
            identifier: "CLIENT_REMINDER",
            actions: [], // Ajoutez des actions personnalisées si nécessaire
            intentIdentifiers: [],
            options: .customDismissAction
        )

        let dailyAlertCategory = UNNotificationCategory(
            identifier: "DAILY_ALERT",
            actions: [], // Ajoutez des actions personnalisées si nécessaire
            intentIdentifiers: [],
            options: .customDismissAction
        )

        // Ajout des catégories au centre des notifications
        UNUserNotificationCenter.current().setNotificationCategories([clientReminderCategory, dailyAlertCategory])
    }

    // Gère l'affichage des notifications lorsque l'application est au premier plan
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Affiche les notifications comme bannières avec son et badge
        completionHandler([.banner, .sound, .badge])
    }
}
