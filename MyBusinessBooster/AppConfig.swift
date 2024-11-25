import SwiftUI
import Foundation

struct AppConfig {
    // MARK: - Activation / Désactivation des fonctionnalités
    static let enableImportExport = true
    static let enableStatistics = true
    static let enablePushNotifications = false

    // MARK: - Limites pour la version d'essai
    static let trialClientLimit = 50
    static let isTrialMode = true

    // Message affiché lorsque la limite d'essai est atteinte
    static let trialLimitMessage = "Vous avez atteint la limite de \(trialClientLimit) clients pour la version d'essai."

    // MARK: - Alerte relance personnalisée
    /// Seuil en jours pour afficher les clients nécessitant une relance
    private static let alertThresholdKey = "alertThreshold" // Clé pour UserDefaults
    @AppStorage(alertThresholdKey) private static var storedAlertThreshold: Int = 15

    static var alertThreshold: Int {
        get { storedAlertThreshold }
        set { storedAlertThreshold = newValue }
    }

    // MARK: - Version de l'application
    static let appVersion = "1.0"

    // MARK: - Liste des pays et préfixes téléphoniques
    struct Country {
        let name: String
        let code: String
    }

    static let countries: [Country] = [
        Country(name: "France", code: "+33"),
        Country(name: "Belgique", code: "+32"),
        Country(name: "Suisse", code: "+41"),
        Country(name: "Canada", code: "+1"),
        Country(name: "États-Unis", code: "+1"),
        Country(name: "Royaume-Uni", code: "+44"),
        Country(name: "Allemagne", code: "+49"),
        Country(name: "Espagne", code: "+34"),
        Country(name: "Italie", code: "+39"),
        Country(name: "Pays-Bas", code: "+31"),
        Country(name: "Portugal", code: "+351"),
        Country(name: "Australie", code: "+61"),
        Country(name: "Chine", code: "+86"),
        Country(name: "Inde", code: "+91"),
        Country(name: "Japon", code: "+81"),
        Country(name: "Mexique", code: "+52"),
        Country(name: "Brésil", code: "+55"),
        Country(name: "Russie", code: "+7"),
        Country(name: "Suède", code: "+46"),
        Country(name: "Norvège", code: "+47"),
        Country(name: "Danemark", code: "+45"),
        Country(name: "Autriche", code: "+43"),
        Country(name: "Irlande", code: "+353"),
        Country(name: "Nouvelle-Zélande", code: "+64"),
        Country(name: "Afrique du Sud", code: "+27"),
        Country(name: "Corée du Sud", code: "+82"),
        Country(name: "Singapour", code: "+65"),
        Country(name: "Hong Kong", code: "+852"),
        Country(name: "Malaisie", code: "+60"),
        Country(name: "Indonésie", code: "+62"),
        Country(name: "Arabie Saoudite", code: "+966"),
        Country(name: "Émirats Arabes Unis", code: "+971"),
        Country(name: "Turquie", code: "+90"),
        Country(name: "Grèce", code: "+30"),
        Country(name: "Pologne", code: "+48"),
        Country(name: "Polynésie", code: "+689"),
        Country(name: "Hongrie", code: "+36"),
        Country(name: "République tchèque", code: "+420"),
        Country(name: "Roumanie", code: "+40"),
        Country(name: "Slovaquie", code: "+421"),
        Country(name: "Finlande", code: "+358"),
        Country(name: "Bulgarie", code: "+359"),
        Country(name: "Argentine", code: "+54"),
        Country(name: "Chili", code: "+56"),
        Country(name: "Colombie", code: "+57"),
        Country(name: "Pérou", code: "+51"),
        Country(name: "Venezuela", code: "+58"),
        Country(name: "Thaïlande", code: "+66"),
        Country(name: "Vietnam", code: "+84"),
        Country(name: "Philippines", code: "+63")
    ]

    // MARK: - Préfixe téléphonique par défaut
    private static let defaultPrefixKey = "defaultPhonePrefix"

    static var defaultPhonePrefix: String {
        get {
            UserDefaults.standard.string(forKey: defaultPrefixKey) ?? "+33" // Préfixe par défaut : France
        }
        set {
            UserDefaults.standard.set(newValue, forKey: defaultPrefixKey)
        }
    }
}
