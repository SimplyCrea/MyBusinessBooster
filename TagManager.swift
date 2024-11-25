import Foundation
import CoreData

class TagManager {
    // Ajout d'un tag
    static func addTag(to client: Client, tag: String, context: NSManagedObjectContext) {
        var existingTags = (client.tags as? [String]) ?? []
        if !existingTags.contains(tag) {
            existingTags.append(tag)
            client.tags = existingTags as NSObject // Sérialisation en NSObject
        }
        saveContext(context)
    }

    // Suppression d'un tag
    static func removeTag(from client: Client, tag: String, context: NSManagedObjectContext) {
        var existingTags = (client.tags as? [String]) ?? []
        existingTags.removeAll { $0 == tag }
        client.tags = existingTags as NSObject // Sérialisation en NSObject
        saveContext(context)
    }

    // Récupération des tags
    static func getTags(for client: Client) -> [String] {
        return (client.tags as? [String]) ?? []
    }

    // Sauvegarde dans Core Data
    private static func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
}
