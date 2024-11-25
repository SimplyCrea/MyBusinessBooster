import SwiftUI
import CoreData
import Foundation

struct ConfigurationView: View {
    // Gestion de préfixes téléphoniques standard
    @AppStorage("defaultPhonePrefix") private var defaultCountryCode: String = "+33" // Préfixe par défaut
    // Message personnalisé SMS
    @AppStorage("customSMSMessage") private var customSMSMessage: String = "Bonjour [Nom du Client],\n\n Nous avons essayé de vous joindre à plusieurs reprises pour discuter de l'avancement de votre projet...\n\n Celui-ci est-il toujours d'actualité ?\n\n Nous restons à votre disposition pour toutes questions techniques, ou pour toutes modifications de votre projet.\n\nCordialement,"
    // Message personnalisé Mail
    @AppStorage("customEmailMessage") private var customEmailMessage: String = "Bonjour [Nom du Client],\n\n Nous avons essayé de vous joindre à plusieurs reprises pour discuter de l'avancement de votre projet...\n\n Celui-ci est-il toujours d'actualité ?\n\n"
    // Système de filtration
    @ObservedObject var dynamicConfig = DynamicAppConfig.shared
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    @ObservedObject var config = DynamicAppConfig.shared
    
    @FetchRequest(
        entity: Client.entity(),
        sortDescriptors: []
    ) private var clients: FetchedResults<Client>

    var body: some View {
        Form {
            // Section Version
                        Section(header: Text("Version de l'application")) {
                            if AppConfig.isTrialMode {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Vous utilisez actuellement la version d'essai.")
                                        .foregroundColor(.orange)
                                    Text("Vous êtes limité à \(AppConfig.trialClientLimit) clients.")
                                        .foregroundColor(.gray)
                                    Button(action: showSubscriptionOptions) {
                                        HStack {
                                            Image(systemName: "star.fill")
                                                .foregroundColor(.yellow)
                                            Text("Passer à la version complète")
                                                .fontWeight(.bold)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .buttonStyle(BorderlessButtonStyle())
                                }
                            } else {
                                Text("Vous utilisez la version complète.")
                                    .foregroundColor(.green)
                            }
                        }
            
            // Section des paramètres généraux
            Section(header: Text("Paramètres généraux")) {
                // Notifications
                Toggle(isOn: .constant(AppConfig.enablePushNotifications)) {
                    Text("Activer les notifications")
                }
                
                
                // Tri clients
                Toggle("Afficher le classement", isOn: $dynamicConfig.showSorting)
                
                // Filtre produit
                Toggle("Afficher le filtre par produit", isOn: $dynamicConfig.showProductFilter)
                
                // Liste des pays pour le préfixes téléphoniques
                Picker("Pays par défaut", selection: $defaultCountryCode) {
                                    ForEach(AppConfig.countries, id: \.code) { country in
                                        Text("\(country.name) (\(country.code))").tag(country.code)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
            
            //Alerte relance personnalisée
            Section(header: Text("Seuil d'alerte (jours)")) {
                        Stepper(value: $config.alertThreshold, in: 1...30) {
                            Text("\(config.alertThreshold) jours")
                        }
                        .onChange(of: config.alertThreshold) { newValue in
                            NotificationCenter.default.post(name: .refreshClients, object: nil)
                        }
                    }
            
            // Section de l'utilisation des clients
            Section(header: Text("Utilisation des Clients")) {
                Text("Clients Réels : \(clients.count)")
                Text("Clients Ajoutés : \(SubscriptionManager.shared.totalClientsAdded) / \(AppConfig.trialClientLimit)")
                ProgressView(value: Double(SubscriptionManager.shared.totalClientsAdded), total: Double(AppConfig.trialClientLimit))
                    .accentColor(SubscriptionManager.shared.totalClientsAdded >= AppConfig.trialClientLimit ? .red : .green)
                Text("Vous pouvez ajouter jusqu'à \(AppConfig.trialClientLimit) clients dans la version d'essai. Abonnez-vous pour lever cette limite.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.top, 5)
            }
        
            // Section pour les messages types
                        Section(header: Text("Gérer mes messages types")) {
                            VStack(alignment: .leading) {
                                Text("Message SMS")
                                    .font(.headline)
                                TextEditor(text: $customSMSMessage)
                                    .frame(height: 100)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                    .padding(.bottom)

                                Text("Message E-mail")
                                    .font(.headline)
                                TextEditor(text: $customEmailMessage)
                                    .frame(height: 150)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                    .padding(.bottom)
                                
                                Button(action: resetMessagesToDefault) {
                                    Text("Restaurer les messages par défaut")
                                        .foregroundColor(.red)
                                }
                                .padding(.top)
                            }
                        }
            
            // Section des informations générales
            Section(header: Text("Informations")) {
                Text("Version de l'application : \(AppConfig.appVersion)")
            }
            
        }
        .navigationTitle("Configuration")
    }

    // Action pour afficher les options d'abonnement
    private func showSubscriptionOptions() {
        // Logique pour lancer la page d'abonnement
        print("Affichez la page d'abonnement ici.")
    }
    
    // Restaurer les messages par défaut
    private func resetMessagesToDefault() {
        customSMSMessage = "Bonjour [Nom du Client],\n\n Nous avons essayé de vous joindre à plusieurs reprises pour discuter de l'avancement de votre projet...\n\n Celui-ci est-il toujours d'actualité ?\n\n Nous restons à votre disposition pour toutes questions techniques, ou pour toutes modifications de votre projet.\n\nCordialement, "
        customEmailMessage = "Bonjour [Nom du Client],\n\n Nous avons essayé de vous joindre à plusieurs reprises pour discuter de l'avancement de votre projet...\n\n Celui-ci est-il toujours d'actualité ?\n\n"
    }
    
}
