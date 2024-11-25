import SwiftUI
import CoreData

struct ClientListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // FetchRequest pour récupérer les clients depuis Core Data
    @FetchRequest(
        entity: Client.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Client.lastInteraction, ascending: false)]
    ) private var clients: FetchedResults<Client>

    // États pour la gestion des filtres et du tri
    @State private var selectedStatus: String = "inProgress"
    @State private var searchText: String = ""
    @State private var selectedSortOption: String = "lastInteractionRecent"

    let sortOptions: [String: String] = [
        "lastInteractionRecent": "Dernière interaction (récente)",
        "lastInteractionOldest": "Dernière interaction (ancienne)",
        "reminderDateRecent": "Date de rappel (récente)",
        "reminderDateOldest": "Date de rappel (ancienne)",
        "nameAscending": "Nom (A → Z)",
        "nameDescending": "Nom (Z → A)"
    ]

    var body: some View {
        NavigationView {
            VStack {
                // Options de tri et de filtre
                VStack(alignment: .leading, spacing: 10) {
                    // Tri
                    HStack {
                        Text("Trier par")
                            .font(.headline)
                        Picker("", selection: $selectedSortOption) {
                            ForEach(sortOptions.keys.sorted(), id: \.self) { key in
                                Text(sortOptions[key] ?? key).tag(key)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: selectedSortOption) { _ in
                            updateFetchRequest()
                        }
                    }

                    // Filtre par statut
                    HStack {
                        Text("Filtrer par statut")
                            .font(.headline)
                        Picker("", selection: $selectedStatus) {
                            Text("En cours").tag("inProgress")
                            Text("Validés").tag("validated")
                            Text("Annulés").tag("cancelled")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .onChange(of: selectedStatus) { _ in
                            updateFetchRequest()
                        }
                    }

                    // Barre de recherche
                    HStack {
                        TextField("Rechercher...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button {
                            updateFetchRequest()
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
                .padding()

                // Liste des clients
                List {
                    // Clients prioritaires
                    Section(header: Text("⚠️ Clients en alerte ⚠️")) {
                        ForEach(prioritizedClients(), id: \.self) { client in
                            NavigationLink(destination: ClientDetailView(client: client)) {
                                ClientRowView(client: client, isPrioritized: true)
                            }
                        }
                    }

                    // Autres clients
                    Section(header: Text("Autres clients")) {
                        ForEach(otherClients(), id: \.self) { client in
                            NavigationLink(destination: ClientDetailView(client: client)) {
                                ClientRowView(client: client, isPrioritized: false)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Liste des Clients")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: ConfigurationView()) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AddClientView()) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    // MARK: - Filtrage des clients
    private func isPrioritized(_ client: Client) -> Bool {
        let interactionGap = Calendar.current.dateComponents([.day], from: client.lastInteraction ?? Date(), to: Date()).day ?? 0
        let isReminderOverdue = client.reminderDate ?? Date() < Date()
        return interactionGap > AppConfig.alertThreshold && isReminderOverdue
    }

    private func prioritizedClients() -> [Client] {
        clients.filter { isPrioritized($0) }
    }

    private func otherClients() -> [Client] {
        clients.filter { !isPrioritized($0) }
    }

    // MARK: - Mise à jour de FetchRequest
    private func updateFetchRequest() {
        var predicates: [NSPredicate] = []

        // Filtre par statut
        predicates.append(NSPredicate(format: "status == %@", selectedStatus))

        // Filtre par recherche
        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "name CONTAINS[cd] %@", searchText))
        }

        clients.nsPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        // Tri dynamique
        let sortDescriptor: NSSortDescriptor
        switch selectedSortOption {
        case "lastInteractionRecent":
            sortDescriptor = NSSortDescriptor(key: "lastInteraction", ascending: false)
        case "lastInteractionOldest":
            sortDescriptor = NSSortDescriptor(key: "lastInteraction", ascending: true)
        case "reminderDateRecent":
            sortDescriptor = NSSortDescriptor(key: "reminderDate", ascending: false)
        case "reminderDateOldest":
            sortDescriptor = NSSortDescriptor(key: "reminderDate", ascending: true)
        case "nameAscending":
            sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        case "nameDescending":
            sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
        default:
            sortDescriptor = NSSortDescriptor(key: "lastInteraction", ascending: false)
        }

        clients.nsSortDescriptors = [sortDescriptor]
    }
}

// MARK: - Ligne d’un client
struct ClientRowView: View {
    let client: Client
    let isPrioritized: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text(client.name ?? "Nom inconnu")
                .font(.headline)
                .foregroundColor(isPrioritized ? .red : .primary)
            if let lastInteraction = client.lastInteraction {
                Text("Dernière interaction : \(formatDate(lastInteraction))")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
