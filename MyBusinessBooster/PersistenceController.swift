import CoreData

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)

        // Ajoutez des données fictives pour l'aperçu
        let viewContext = controller.container.viewContext
        for index in 0..<10 {
            let newClient = Client(context: viewContext)
            newClient.name = "Client \(index)"
            newClient.phone = "123456789\(index)"
            newClient.email = "client\(index)@example.com"
            newClient.lastInteraction = Date()
            newClient.reminderDate = Calendar.current.date(byAdding: .day, value: index, to: Date())
            newClient.status = "inProgress"
        }
        do {
            try viewContext.save()
        } catch {
            print("Erreur lors de la sauvegarde des données fictives : \(error)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MyBusinessBooster")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Erreur lors du chargement des Core Data stores : \(error)")
            }
        }
    }
}
