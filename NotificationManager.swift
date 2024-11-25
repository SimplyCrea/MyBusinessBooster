import UserNotifications
import CoreData
import UIKit

final class NotificationManager {
    static let shared = NotificationManager() // Singleton
    
    /// Met à jour le badge de l'application avec le nombre de notifications en attente
    func updateAppBadge() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = requests.count
                print("📛 Badge mis à jour : \(requests.count) notifications en attente.")
            }
        }
    }

    /// Demande la permission de recevoir des notifications locales
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Erreur lors de la demande d'autorisation : \(error.localizedDescription)")
            } else if !granted {
                print("L'utilisateur a refusé les autorisations de notification.")
            } else {
                print("Notifications autorisées avec alertes, badges et sons.")
            }
        }
    }

    /// Planifie une notification de rappel pour un client
    func scheduleClientReminder(for client: Client) {
        guard let name = client.name, let reminderDate = client.reminderDate else { return }

        let content = UNMutableNotificationContent()
        content.title = "Rappel - \(name)"
        content.body = "N'oubliez pas de vérifier les détails du produit \(client.product ?? "non spécifié")."
        content.sound = .default
        content.userInfo = [
            "clientID": client.objectID.uriRepresentation().absoluteString
        ]
        print("🛎️ Notification créée : \(content.userInfo)")

        let triggerDate = Calendar.current.dateComponents(in: TimeZone.current, from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: client.objectID.uriRepresentation().absoluteString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur lors de la planification de la notification : \(error.localizedDescription)")
            } else {
                print("Notification planifiée pour \(name) à \(reminderDate).")
                self.updateBadgeForPendingNotifications() // Mettez à jour le badge après planification
            }
        }
    }

    /// Planifie une notification quotidienne pour les clients en alerte
    func scheduleDailyAlerts(clients: [Client]) {
        let alertCount = clients.count
        guard alertCount > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Clients en alerte"
        content.body = "Vous avez \(alertCount) client(s) à suivre aujourd'hui."
        content.sound = .default

        let triggerDate = DateComponents(hour: 9, minute: 0) // Exemple : à 9h00 chaque jour
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-alerts",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur lors de la planification de la notification quotidienne : \(error.localizedDescription)")
            } else {
                print("Notification quotidienne planifiée avec succès.")
            }
        }
    }

    /// Réinitialise une notification et met à jour le badge
    func rescheduleNotification(for client: Client) {
        // Annulez l'ancienne notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [client.objectID.uriRepresentation().absoluteString])
        
        // Replanifiez une nouvelle notification si la date est valide
        guard let reminderDate = client.reminderDate, reminderDate > Date() else {
            print("Aucune notification replanifiée : date invalide ou passée.")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Rappel : \(client.name ?? "Client")"
        content.body = "Produit : \(client.product ?? "Non spécifié"). Consultez la fiche client pour plus de détails."
        content.sound = .default
        content.categoryIdentifier = "CLIENT_REMINDER"

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(
            identifier: client.objectID.uriRepresentation().absoluteString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur lors de la replanification de la notification : \(error.localizedDescription)")
            } else {
                print("Notification replanifiée pour \(client.name ?? "Nom inconnu") à \(reminderDate).")
                self.updateBadgeForPendingNotifications() // Mettez à jour le badge après planification
            }
        }
    }

    /// Affiche les notifications en attente dans les journaux
    func logPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📋 Notifications en attente : \(requests.count)")
            for request in requests {
                print("🛎️ Notification ID : \(request.identifier), contenu : \(request.content.body)")
            }
        }
    }

    /// Met à jour le badge uniquement pour les notifications futures
    func updateBadgeForPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let pendingNotificationsCount = requests.filter { request in
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let triggerDate = trigger.nextTriggerDate(),
                   triggerDate > Date() {
                    return true
                }
                return false
            }.count
            
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = pendingNotificationsCount
                print("🔴 Badge mis à jour : \(pendingNotificationsCount) notifications en attente.")
            }
        }
    }
}
