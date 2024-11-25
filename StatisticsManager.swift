
import Foundation
import CoreData

class StatisticsManager {
    static func calculateAverageDecisionTime(context: NSManagedObjectContext) -> Double {
        let fetchRequest: NSFetchRequest<Client> = Client.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "status == %@", "validated")

        do {
            let clients = try context.fetch(fetchRequest)
            let totalDays = clients.compactMap { client -> Double? in
                guard let firstContact = client.lastInteraction, let orderDate = client.reminderDate else {
                    return nil
                }
                return orderDate.timeIntervalSince(firstContact) / (60 * 60 * 24) // Convertir en jours
            }.reduce(0, +)

            return clients.isEmpty ? 0 : totalDays / Double(clients.count)
        } catch {
            print("Erreur lors du calcul du temps moyen : \(error.localizedDescription)")
            return 0
        }
    }

    static func countClientsByStatus(context: NSManagedObjectContext) -> [String: Int] {
        let statuses = ["inProgress", "validated", "cancelled"]
        var result: [String: Int] = [:]

        for status in statuses {
            let fetchRequest: NSFetchRequest<Client> = Client.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "status == %@", status)

            do {
                let count = try context.count(for: fetchRequest)
                result[status] = count
            } catch {
                print("Erreur lors du comptage des clients pour le statut \(status) : \(error.localizedDescription)")
                result[status] = 0
            }
        }

        return result
    }
}
