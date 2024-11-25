import Foundation
import Combine

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var clientCount: Int = 0 // Nombre réel de clients enregistrés
    @Published var isSubscribed: Bool = false
    @Published var totalClientsAdded: Int = 0 // Nouveau : Total des clients ajoutés
    let clientLimit = AppConfig.trialClientLimit // Limite pour la version gratuite

    private init() {
        loadSubscriptionStatus()
        loadClientCount()
        loadTotalClientsAdded() // Charge le total des clients ajoutés
    }

    // Vérifie si la limite est atteinte
    var clientLimitReached: Bool {
        return !isSubscribed && totalClientsAdded >= clientLimit
    }

    // Incrémente le compteur de clients (réel et total)
    func incrementClientCount() {
        clientCount += 1
        totalClientsAdded += 1
        saveClientCount()
        saveTotalClientsAdded()
    }

    // Met à jour le compteur de clients (uniquement réel)
    func updateClientCount(_ count: Int) {
        clientCount = count
        saveClientCount()
    }

    // Charge le total des clients ajoutés
    private func loadTotalClientsAdded() {
        totalClientsAdded = UserDefaults.standard.integer(forKey: "totalClientsAdded")
    }

    // Sauvegarde le total des clients ajoutés
    private func saveTotalClientsAdded() {
        UserDefaults.standard.set(totalClientsAdded, forKey: "totalClientsAdded")
    }

    // Charge le compteur de clients
    private func loadClientCount() {
        clientCount = UserDefaults.standard.integer(forKey: "clientCount")
    }

    // Sauvegarde le compteur de clients
    private func saveClientCount() {
        UserDefaults.standard.set(clientCount, forKey: "clientCount")
    }

    // Charge le statut de l'abonnement
    private func loadSubscriptionStatus() {
        isSubscribed = UserDefaults.standard.bool(forKey: "isSubscribed")
    }

    // Sauvegarde le statut d'abonnement
    func saveSubscriptionStatus(_ subscribed: Bool) {
        isSubscribed = subscribed
        UserDefaults.standard.set(subscribed, forKey: "isSubscribed")
    }
}
