import CoreData

class ModificationManager {
    static func addModification(to client: Client, modification: String, context: NSManagedObjectContext) {
        var history = (client.modificationHistory as? [String]) ?? []
        history.append(modification)
        client.modificationHistory = history as NSObject // Conversion en NSObject
        saveContext(context)
    }

    static func clearModifications(for client: Client, context: NSManagedObjectContext) {
        client.modificationHistory = [] as NSObject // Conversion en NSObject pour effacer l'historique
        saveContext(context)
    }

    private static func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
}
