import SwiftUI
import CoreData
import UserNotifications

struct ClientDetailView: View {
    let viewContext: NSManagedObjectContext
    @ObservedObject var client: Client

    // États pour gérer les données et les interactions
    @State private var newNote: String = "" // Pour ajouter une nouvelle note
    @State private var newTag: String = "" // Pour ajouter un nouveau tag
    @State private var selectedStatus: String = "" // Statut sélectionné (En cours, Validé, Annulé)
    @State private var showValidationFields = false // Affiche les champs pour le statut "Validé"
    @State private var firstQuoteDate: Date = Date() // Date du premier contact
    @State private var validationDate: Date = Date() // Date de validation
    @State private var validatedAmount: String = "" // Montant validé (sous forme de texte pour permettre la saisie)
    @State private var showSMSAlert = false // Affiche une alerte pour l'échec d'envoi de SMS
    @State private var showEmailAlert = false // Affiche une alerte pour l'échec d'envoi d'email
    @State private var reminderDate: Date = Date() // Date et heure du rappel
    @State private var validationError: ValidationError? = nil // Erreur pour la validation des champs
    @State private var isReminderDateModified = false // Indique si la date de rappel a été modifiée
    @State private var isFirstAppear: Bool = true // Évite la réinitialisation au premier affichage
    @State private var isStatusInitialized = false
    @State private var navigateToClient: Client? = nil

    // Messages personnalisés
    @AppStorage("customSMSMessage") private var customSMSMessage: String = ""
    @AppStorage("customEmailMessage") private var customEmailMessage: String = ""

    // Struct pour gérer les erreurs de validation
    struct ValidationError: Identifiable {
        let id = UUID()
        let message: String
    }

    var body: some View {
        Form {
            // Informations générales sur le client
            Section(header: Text("Informations générales")) {
                Text("Nom : \(client.name ?? "Nom inconnu")")
                HStack {
                    Text("Téléphone : \(client.phone ?? "Téléphone inconnu")")
                    Spacer()
                    if let phone = client.phone, !phone.isEmpty {
                        Button(action: {
                            makeCall(to: phone)
                        }) {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
                Text("Email : \(client.email ?? "Email non fourni")")
                Text("Produit : \(client.product ?? "Non spécifié")")
                if let firstQuoteDate = client.firstQuoteDate {
                    Text("Client ajouté le \(formatDate(firstQuoteDate))")
                        .font(.footnote)
                        .foregroundColor(.gray)
                } else {
                    Text("Date d'ajout non disponible")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }

            // Notes du client
            Section(header: Text("Notes")) {
                if let notes = client.notes {
                    ForEach(notes.split(separator: "\n").map(String.init), id: \.self) { note in
                        Text(note)
                            .multilineTextAlignment(.leading)
                    }
                }
                HStack {
                    TextField("Ajouter une nouvelle note", text: $newNote)
                    Button(action: addNote) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
            }

            // Actions disponibles
            Section(header: Text("Actions")) {
                if let phone = client.phone, !phone.isEmpty {
                    Button("Envoyer un SMS") {
                        sendSMS(to: phone)
                    }
                }
                if let email = client.email, !email.isEmpty {
                    Button("Envoyer un Email") {
                        sendEmail(to: email)
                    }
                }
            }

            // Gestion des tags
            Section(header: Text("Tags")) {
                if let tags = client.tags as? [String], !tags.isEmpty {
                    ForEach(tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button(action: {
                                removeTag(tag)
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } else {
                    Text("Aucun tag ajouté.")
                        .foregroundColor(.gray)
                }
                HStack {
                    TextField("Ajouter un nouveau tag", text: $newTag)
                    Button(action: addTag) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.blue)
                    }
                }
            }

            // Statut du client
            Section(header: Text("Statut")) {
                Picker("Statut", selection: $selectedStatus) {
                    Text("En cours").tag("inProgress")
                    Text("Validé").tag("validated")
                    Text("Annulé").tag("cancelled")
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectedStatus) { newStatus in
                    if isStatusInitialized && client.status != newStatus {
                        client.status = newStatus
                        addToHistory(action: "Statut modifié en \(newStatus)")
                        saveContext()
                    }
                }
            }

            // Champs spécifiques pour le statut "Validé"
            if showValidationFields {
                Section(header: Text("Informations de Validation")) {
                    DatePicker("Date du premier contact", selection: $firstQuoteDate, displayedComponents: .date)
                    DatePicker("Date de validation", selection: $validationDate, displayedComponents: .date)
                    TextField("Montant HT (€)", text: $validatedAmount)
                        .keyboardType(.decimalPad)
                }
            }

            // Gestion des rappels
            Section(header: Text("Rappel")) {
                DatePicker("Date et Heure", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                    .onChange(of: reminderDate) { _ in
                        isReminderDateModified = true
                    }
                if isReminderDateModified {
                    Button("Valider le rappel") {
                        saveReminderDate()
                    }
                    .padding(.top, 5)
                    .buttonStyle(.borderedProminent)
                }
            }

            // Historique des modifications
            Section(header: Text("Historique des modifications")) {
                if let modificationHistory = client.modificationHistory as? [String], !modificationHistory.isEmpty {
                    // Utilisation de `enumerated` pour fournir un index unique à chaque élément
                    ForEach(Array(modificationHistory.reversed().enumerated()), id: \.offset) { index, modification in
                        Text(modification)
                            .font(.footnote)
                            .foregroundColor(.gray)
                            .padding(4)
                            .background(index % 2 == 0 ? Color(UIColor.systemGray6) : Color(UIColor.systemGray4)) // Alternance de couleur
                            .cornerRadius(4)
                    }
                } else {
                    Text("Aucune modification enregistrée.")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Détails du Client")
        .onAppear {
            initializeView()
            if !isStatusInitialized {
                selectedStatus = client.status ?? "inProgress"
                isStatusInitialized = true // Marque l'initialisation comme terminée
            }
            // Initialisation des autres champs
            reminderDate = client.reminderDate ?? Date()
            firstQuoteDate = client.firstQuoteDate ?? Date()
            validationDate = client.validationDate ?? Date()
            validatedAmount = String(format: "%.2f", client.validatedAmount)

            // Vérification supplémentaire
            print("🎯 Détails Client - Nom : \(client.name ?? "Nom inconnu"), Statut : \(client.status ?? "inconnu")")
        }
    
        .alert(item: $validationError) { error in
            Alert(title: Text("Erreur"), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }

    // Initialisation des données
    private func initializeView() {
        if selectedStatus.isEmpty {
            selectedStatus = client.status ?? "inProgress"
        }
        reminderDate = client.reminderDate ?? Date()
        firstQuoteDate = client.firstQuoteDate ?? Date()
        validationDate = client.validationDate ?? Date()
        validatedAmount = String(format: "%.2f", client.validatedAmount)
    }

    // Ajout de notes
    private func addNote() {
        guard !newNote.isEmpty else { return }
        let noteWithDate = "\(formatDate(Date())): \(newNote)"
        client.notes = ((client.notes ?? "") + "\n" + noteWithDate).trimmingCharacters(in: .whitespacesAndNewlines)
        newNote = ""
        saveContext()
        addToHistory(action: "Note ajoutée : \(noteWithDate)")
    }

    // Ajout de tags
    private func addTag() {
        guard !newTag.isEmpty else { return }
        var tags = client.tags as? [String] ?? []
        tags.append(newTag)
        client.tags = tags as NSObject
        saveContext()
        addToHistory(action: "Tag ajouté : \(newTag)")
    }

    // Suppression de tags
    private func removeTag(_ tag: String) {
        var tags = client.tags as? [String] ?? []
        tags.removeAll { $0 == tag }
        client.tags = tags as NSObject
        saveContext()
        addToHistory(action: "Tag supprimé : \(tag)")
    }

    // Sauvegarde de la date de rappel
    private func saveReminderDate() {
        client.reminderDate = reminderDate
        addToHistory(action: "Date et heure de rappel modifiées à \(formatDate(reminderDate))")
        saveContext()
        
        // Replanifiez la notification après modification
        NotificationManager.shared.rescheduleNotification(for: client)
        
        isReminderDateModified = false // Réinitialisez l'état
    }

    // Sauvegarde des données dans Core Data
    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Erreur lors de la sauvegarde : \(error.localizedDescription)")
        }
    }

    // Formatage des dates
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // Envoi du SMS
    private func sendSMS(to phoneNumber: String) {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("Impossible de trouver le contrôleur racine.")
            return
        }

        // Personnaliser le message avec le nom du client
        let personalizedMessage = customSMSMessage.replacingOccurrences(of: "[Nom du Client]", with: client.name ?? "Client")

        // Utiliser un helper pour envoyer le SMS
        CommunicationHelper.shared.sendSMS(
            to: phoneNumber,
            body: personalizedMessage,
            from: rootViewController
        )

        // Mettre à jour la date de dernière interaction
        updateLastInteraction()
        // Ajouter l'action à l'historique
        addToHistory(action: "SMS envoyé à \(phoneNumber)")
    }
    
    //Envoi du mail
    private func sendEmail(to email: String) {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("Impossible de trouver le contrôleur racine.")
            return
        }

        // Personnaliser le message avec le nom du client
        let personalizedMessage = customEmailMessage.replacingOccurrences(of: "[Nom du Client]", with: client.name ?? "Client")

        // Utiliser un helper pour envoyer l'email
        CommunicationHelper.shared.sendEmail(
            to: email,
            subject: "Suivi de votre projet",
            body: personalizedMessage,
            from: rootViewController
        )

        // Mettre à jour la date de dernière interaction
        updateLastInteraction()
        // Ajouter l'action à l'historique
        addToHistory(action: "Email envoyé à \(email)")
    }
    
    // Lancement de l'appel
    private func makeCall(to phoneNumber: String) {
        guard let url = URL(string: "tel://\(phoneNumber)") else {
            print("Numéro de téléphone invalide")
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            // Mettre à jour la date de dernière interaction
            updateLastInteraction()
            // Ajouter l'action à l'historique
            addToHistory(action: "Appel effectué au \(phoneNumber)")
        } else {
            print("Appel non pris en charge sur cet appareil")
        }
    }
    
    // Planification d'un rappel
    func scheduleNotification(for client: Client) {
        let content = UNMutableNotificationContent()
        content.title = "Rappel - \(client.name ?? "Client")"
        content.body = "N'oubliez pas de contacter \(client.name ?? "le client")."
        content.sound = .default
        content.userInfo = [
            "clientID": client.objectID.uriRepresentation().absoluteString
        ]
        print("🛎️ Notification planifiée pour \(client.name ?? "Nom inconnu") avec ID : \(client.objectID.uriRepresentation().absoluteString)")

        if let reminderDate = client.reminderDate {
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Erreur lors de la planification de la notification : \(error.localizedDescription)")
                } else {
                    print("Notification planifiée pour \(client.name ?? "Nom inconnu") à \(reminderDate).")
                }
            }
        }
    }
    
    // Sauvegarde de la date de rappel
    private func saveReminder() {
        // Enregistrement de la date de rappel
        client.reminderDate = reminderDate
        saveContext()

        // Planification de la notification
        scheduleNotification(for: client)
    }
    
    // Mise à jour de la dernière interaction
    private func updateLastInteraction() {
        client.lastInteraction = Date()
        saveContext()
    }
    
    // Mise à jour des changements dans l'historique du client
    private func addToHistory(action: String) {
        // Formater la date et l'heure pour l'historique
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short)
        let historyEntry = "\(timestamp): \(action)"
        
        // Récupérer l'historique actuel (ou en créer un vide s'il n'existe pas encore)
        var currentHistory = client.modificationHistory as? [String] ?? []
        currentHistory.append(historyEntry)
        
        // Mettre à jour l'historique dans le modèle Core Data
        client.modificationHistory = currentHistory as NSObject
        
        // Sauvegarder les modifications dans Core Data
        saveContext()
    }
}
