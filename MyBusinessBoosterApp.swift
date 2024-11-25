import SwiftUI
import CoreData
import BackgroundTasks
import UserNotifications

@main
struct MyBusinessBoosterApp: App {
    // Adopte AppDelegate pour gérer les événements système
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Utilisation de `StateObject` pour partager le contrôleur de persistance
    @StateObject private var persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            // Vue principale de l'application, avec le contexte Core Data fourni explicitement
            ClientListView(viewContext: persistenceController.container.viewContext)
                .environment(\.managedObjectContext, persistenceController.container.viewContext) // Fournit le contexte CoreData
                .onAppear {
                    // Initialise les notifications et les tâches d'arrière-plan
                    initializeApp()
                }
        }
    }

    /// Initialisation des notifications et des tâches d'arrière-plan
    private func initializeApp() {
        // Supprime toutes les notifications en attente ou livrées au lancement de l'application
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Demande la permission pour les notifications
        NotificationManager.shared.requestPermission()
        
        // Configure les tâches d'arrière-plan
        setupBackgroundTasks()
        
        // Planifie les notifications nécessaires
        scheduleNotifications()
        
        // Affiche dans le log les notifications en attente (utile pour le débogage)
        NotificationManager.shared.logPendingNotifications()
    }

    /// Configure les tâches d'arrière-plan
    private func setupBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.mybusinessbooster.backgroundrefresh", using: nil) { task in
            // Traite les tâches d'arrière-plan (exemple : actualiser les notifications)
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
    }

    /// Planifie toutes les notifications nécessaires
    private func scheduleNotifications() {
        let fetchRequest: NSFetchRequest<Client> = Client.fetchRequest()
        do {
            let clients = try persistenceController.container.viewContext.fetch(fetchRequest)
            
            // Planifie les rappels individuels pour chaque client
            for client in clients where client.reminderDate != nil {
                NotificationManager.shared.scheduleClientReminder(for: client)
            }
            
            // Identifie les clients nécessitant une alerte quotidienne (basé sur la dernière interaction)
            let alertedClients = clients.filter { client in
                let interactionGap = Calendar.current.dateComponents([.day], from: client.lastInteraction ?? Date(), to: Date()).day ?? 0
                return interactionGap > AppConfig.alertThreshold && client.reminderDate ?? Date() < Date()
            }
            
            // Planifie une alerte quotidienne pour les clients en alerte
            NotificationManager.shared.scheduleDailyAlerts(clients: alertedClients)
        } catch {
            // Gère les erreurs de récupération des données CoreData
            print("Erreur lors de la récupération des clients : \(error.localizedDescription)")
        }
    }

    /// Gère les tâches d'arrière-plan
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        // Replanifie les notifications
        scheduleNotifications()
        
        // Indique que la tâche a été complétée avec succès
        task.setTaskCompleted(success: true)
        
        // Programme la prochaine tâche d'arrière-plan
        scheduleNextBackgroundTask()
    }

    /// Planifie la prochaine tâche d'arrière-plan
    func scheduleNextBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.mybusinessbooster.backgroundrefresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600) // Dans 1 heure

        do {
            // Soumet la tâche d'arrière-plan
            try BGTaskScheduler.shared.submit(request)
        } catch {
            // Affiche une erreur si la tâche ne peut pas être programmée
            print("Erreur lors de la programmation de la tâche en arrière-plan : \(error.localizedDescription)")
        }
    }
}
