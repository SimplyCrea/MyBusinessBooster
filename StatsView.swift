import SwiftUI
import CoreData

struct StatsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        VStack {
            Text("Statistiques")
                .font(.largeTitle)
                .padding()

            // Exemple d'affichage du nombre de clients
            Text("Nombre de clients : \(fetchClientCount())")
                .font(.headline)
                .padding()
        }
    }

    private func fetchClientCount() -> Int {
        let request: NSFetchRequest<Client> = Client.fetchRequest()
        do {
            let clients = try viewContext.fetch(request)
            return clients.count
        } catch {
            print("Erreur lors du chargement des clients : \(error)")
            return 0
        }
    }
}

struct StatsView_Previews: PreviewProvider {
    static var previews: some View {
        StatsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
