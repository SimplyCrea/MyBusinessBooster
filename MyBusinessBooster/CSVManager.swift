
import Foundation
import CoreData
import UniformTypeIdentifiers

class CSVManager {
    static func importClients(from csvContent: String, context: NSManagedObjectContext) {
        let rows = csvContent.components(separatedBy: "\n")
        let header = rows.first?.components(separatedBy: ",") ?? []
        
        guard header.contains("name"), header.contains("phone") else {
            print("Fichier CSV invalide : colonnes 'name' et 'phone' obligatoires.")
            return
        }
        
        for row in rows.dropFirst() {
            let columns = row.components(separatedBy: ",")
            guard columns.count >= 2 else { continue }

            let name = columns[header.firstIndex(of: "name") ?? 0].trimmingCharacters(in: .whitespacesAndNewlines)
            let phone = columns[header.firstIndex(of: "phone") ?? 1].trimmingCharacters(in: .whitespacesAndNewlines)
            let email = header.contains("email") ? columns[header.firstIndex(of: "email") ?? 2].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            let notes = header.contains("notes") ? columns[header.firstIndex(of: "notes") ?? 3].trimmingCharacters(in: .whitespacesAndNewlines) : ""

            let fetchRequest: NSFetchRequest<Client> = Client.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "phone == %@", phone)
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.isEmpty {
                    let newClient = Client(context: context)
                    newClient.name = name
                    newClient.phone = phone
                    newClient.email = email
                    newClient.notes = notes
                    newClient.lastInteraction = Date()
                    newClient.status = "inProgress"
                }
            } catch {
                print("Erreur lors de la vérification des doublons : \(error.localizedDescription)")
            }
        }
        
        saveContext(context)
    }

    static func exportClients(to context: NSManagedObjectContext) -> String {
        let fetchRequest: NSFetchRequest<Client> = Client.fetchRequest()
        
        do {
            let clients = try context.fetch(fetchRequest)
            var csvContent = "name,phone,email,notes,status,lastInteraction\n"
            
            for client in clients {
                let name = client.name ?? ""
                let phone = client.phone ?? ""
                let email = client.email ?? ""
                let notes = client.notes ?? ""
                let status = client.status ?? ""
                let lastInteraction = client.lastInteraction?.description ?? ""
                
                let row = "\(name),\(phone),\(email),\(notes),\(status),\(lastInteraction)"
                csvContent += row + "\n"
            }
            
            return csvContent
        } catch {
            print("Erreur lors de l'exportation des clients : \(error.localizedDescription)")
            return ""
        }
    }

    private static func saveContext(_ context: NSManagedObjectContext) {
        do {
            try context.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }
}
