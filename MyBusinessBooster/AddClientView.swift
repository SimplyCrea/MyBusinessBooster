import SwiftUI
import CoreData

struct AddClientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    @State private var name: String = "" // Nom du client
    @State private var phone: String = "" // Numéro de téléphone
    @State private var email: String = "" // E-mail du client
    @AppStorage("defaultPhonePrefix") private var selectedCountryCode: String = "+33" // Gestion de l'indicatif
    @State private var notes: String = ""
    @State private var lastInteraction: Date = Date()
    @State private var reminderDate: Date = Date()
    @State private var selectedProduct: String = "Non Renseigné"
    @State private var newProduct: String = ""
    @State private var tags: [String] = [] // Liste vide par défaut
    @State private var newTag: String = "" // Tag en cours d'ajout
    @State private var showSubscriptionAlert = false
    @State private var products: [String] = UserDefaults.standard.stringArray(forKey: "products") ?? ["Non Renseigné"]
    @State private var showEmailAlert = false
    private let googlePlacesAPIKey = "AIzaSyBuKm-AciwbUjumLSH_BbFvQQ1bpC44bjs" // Auto remplissage adresse
    @State private var address: String = "" // Adresse du client
    @State private var addressSuggestions: [String] = [] // Suggestions d'adresses
    @State private var isFetchingSuggestions: Bool = false // Indicateur pour le chargement
    
    // Bulles d'information
    @State private var showTagInfo: Bool = false
    @State private var showProductInfo: Bool = false
    @State private var showNotesInfo: Bool = false

    
    
    var body: some View {
        Form {
            if subscriptionManager.clientLimitReached {
                        Section {
                            Text("Limite atteinte : Abonnez-vous pour ajouter plus de clients.")
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                }
            } else {
                // Section Informations Client
                Section(header: Text("Informations Client")) {
                    TextField("Nom / Prénom", text: $name)
                    
                    // Champ Adresse
                    Section(header: Text("Adresse")) {
                        TextField("Adresse", text: $address)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: address) { newValue in
                                fetchAddressSuggestions(for: newValue)
                            }

                        if isFetchingSuggestions {
                            ProgressView("Recherche des suggestions...")
                        } else if !addressSuggestions.isEmpty {
                            List(addressSuggestions, id: \.self) { suggestion in
                                Button(action: {
                                    address = suggestion
                                    addressSuggestions = [] // Efface les suggestions après sélection
                                }) {
                                    Text(suggestion)
                                }
                            }
                            .frame(height: 150) // Limite la hauteur de la liste
                        }
                    }
                    
                    // Sélection du pays et champ pour le téléphone
                    Section(header: Text("Téléphone")) {
                        // Picker pour sélectionner le pays
                        Picker("Pays", selection: $selectedCountryCode) {
                            ForEach(AppConfig.countries, id: \.code) { country in
                                Text("\(country.name) (\(country.code))").tag(country.code)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())

                        // Champ de saisie pour le téléphone
                        HStack {
                            Text(selectedCountryCode) // Affiche l'indicatif du pays
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(5)

                            TextField("Numéro de téléphone", text: $phone)
                                .keyboardType(.phonePad) // Affiche un clavier numérique
                        }
                    }
                    
                    // Champ pour l'e-mail
                    TextField("E-mail", text: $email)
                        .keyboardType(.emailAddress) // Clavier adapté pour les e-mails
                }
                
                .alert(isPresented: $showEmailAlert) {
                    Alert(
                        title: Text("Adresse e-mail invalide"),
                        message: Text("Veuillez entrer une adresse e-mail valide."),
                        dismissButton: .default(Text("OK"))
                    )
                }

                // Section Détails
                Section(header: Text("Détails")) {
                    DatePicker("Dernière interaction", selection: $lastInteraction, displayedComponents: .date)
                    DatePicker("Date de rappel", selection: $reminderDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                // Section Notes
                Section(header: HStack {
                    Text("Notes")
                    Button(action: {
                        showNotesInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .popover(isPresented: $showNotesInfo) {
                        ScrollView {
                            VStack {
                                Text("""
                                    Les notes sont un moyen important de se mémoriser des éléments étant ou paraissant importants pour le client.\n\n
                                    Par exemple, si votre note stipule que le client(e) est récemment devenu(e) parent d'une petite fille appelée Rose, lors de votre rappel, vous pourrez poliment demander si tout se passe avec la petite Rose.\n\n
                                    Ce genre d'exemple permet de montrer aux clients l'intérêt que vous leur portez et pourra à un moment faire basculer la balance vers votre société plutôt que celle d'un de vos confrères...\n\n
                                    Ne négligez pas la puissance du contact commercial, il peut bien souvent être plus fort que la différence de prix...\n\n
                                    Il est possible de rajouter des notes par la suite sur la fiche clients.
                                    """)
                                    .padding()
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Button("OK") {
                                    showNotesInfo = false
                                }
                                .padding(.top, 10)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .frame(width: 370, height: 650)
                    }
                }) {
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Ajouter une note (facultatif)")
                                .foregroundColor(.gray)
                                .padding(.leading, 5)
                                .padding(.top, 8)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 100) // Hauteur minimale pour faciliter la saisie
                            .cornerRadius(8) // Ajoute des coins arrondis
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray, lineWidth: 1) // Bordure grise autour du champ
                            )
                            .padding(4) // Ajoute un peu d'espace intérieur
                    }
                }


                
                // Produits
                Section(header: HStack {
                    Text("Produit")
                    Button(action: {
                        showProductInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .popover(isPresented: $showProductInfo) {
                        ScrollView {
                            VStack {
                                Text("""
                                    Lorsque vous ajoutez un produit, celui-ci est réutilisable sur toutes les nouvelles fiches que vous allez créer.\n\n
                                    Il n'est pas obligatoire de le renseigner, toutefois, l'application pourra l'intégrer dans des statistiques qui vous permettront un meilleur ciblage ou une meilleure compréhension des habitudes d'achats de vos clients.\n
                                    """)
                                    .padding()
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true) // Empêche la troncature
                                Button("OK") {
                                    showProductInfo = false
                                }
                                .padding(.top, 10)
                            }
                            .frame(width: 370) // Augmente la largeur pour mieux accueillir le texte
                        }
                        .frame(width: 370, height: 650) // Augmente la hauteur totale
                    }

                }) {
                    Picker("Produit", selection: $selectedProduct) {
                        ForEach(products, id: \.self) { product in
                            Text(product)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    // Ajouter un nouveau produit
                    HStack {
                        TextField("Ajouter un produit", text: $newProduct)
                        Button(action: addNewProduct) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }


                // Section Tags
                Section(header: HStack {
                    Text("Tags")
                    Button(action: {
                        showTagInfo.toggle()
                    }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .popover(isPresented: $showTagInfo) {
                        ScrollView {
                            VStack {
                                Text("""
                                Les tags sont optionnels et servent à retrouver un client basé sur des détails que vous associez à celui-ci.\n\n
                                Vous pouvez ajouter autant de tags que vous le souhaitez pour faciliter la recherche.\n
                                Par exemple :\n
                                - Possède un immense chat noir\n
                                - Petite maison verte\n
                                - Personne stressée\n
                                - Lunette verte\n
                                - ...\n
                                \n
                                Le but est de créer un moyen mémo techniques pour retrouver le client sans se souvenir de son nom...\n
                                """)
                                    .padding()
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true) // Empêche la troncature
                                Button("OK") {
                                    showTagInfo = false
                                }
                                .padding(.top, 10)
                            }
                            .frame(width: 370) // Augmente la largeur pour mieux accueillir le texte
                        }
                        .frame(width: 370, height: 650) // Augmente la hauteur totale
                    }
                }) {
                    if tags.isEmpty {
                        Text("Aucun tag ajouté.")
                            .foregroundColor(.gray)
                    } else {
                        ForEach(tags, id: \.self) { tag in
                            HStack {
                                Text(tag)
                                Spacer()
                                Button(action: {
                                    tags.removeAll { $0 == tag }
                                }) {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    HStack {
                        TextField("Ajouter un tag", text: $newTag)
                        Button(action: {
                            guard !newTag.isEmpty else { return }
                            tags.append(newTag)
                            newTag = ""
                        }) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Section Ajouter le Client
                Section {
                    Button("Ajouter le Client") {
                        if subscriptionManager.clientLimitReached {
                            showSubscriptionAlert = true
                        } else {
                            addClient()
                        }
                    }
                }
            }
        }
        .navigationTitle("Ajouter un Client")
        .alert(isPresented: $showSubscriptionAlert) {
            Alert(
                title: Text("Limite atteinte"),
                message: Text(AppConfig.trialLimitMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }
    
    private func addNewProduct() {
        guard !newProduct.isEmpty else { return }
        products.append(newProduct)
        UserDefaults.standard.set(products, forKey: "products") // Sauvegarde persistante
        newProduct = ""
    }
    
    
    private func addClient() {
        guard !name.isEmpty, !phone.isEmpty else {
            print("Nom et téléphone sont obligatoires.")
            return
        }
        
        // Vérification de la limite d'essai
        if SubscriptionManager.shared.clientLimitReached {
            showSubscriptionAlert = true
            return
        }
        
        // Vérification de l'e-mail
        if !email.isEmpty && !isValidEmail(email) {
            showEmailAlert = true
            return
        }

        let newClient = Client(context: viewContext)
        newClient.name = name
        newClient.phone = phone
        newClient.email = email
        newClient.notes = notes
        newClient.lastInteraction = lastInteraction
        newClient.reminderDate = reminderDate
        newClient.status = "inProgress"
        newClient.tags = tags as NSObject // Sauvegarder les tags
        newClient.product = selectedProduct // Enregistrement du produit
        newClient.firstQuoteDate = Date() // Initialisation avec la date actuelle

        do {
            try viewContext.save()
            SubscriptionManager.shared.incrementClientCount()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Erreur lors de l'ajout du client : \(error.localizedDescription)")
        }
    }
    
    // Fonction remplissage adresse
    private func fetchAddressSuggestions(for input: String) {
        guard !input.isEmpty else {
            addressSuggestions = []
            return
        }

        isFetchingSuggestions = true

        let urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(input)&key=\(googlePlacesAPIKey)&types=address"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            print("URL invalide.")
            isFetchingSuggestions = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            defer { isFetchingSuggestions = false }
            guard let data = data, error == nil else {
                print("Erreur lors de la récupération des suggestions : \(error?.localizedDescription ?? "Inconnue")")
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let predictions = json["predictions"] as? [[String: Any]] {
                    DispatchQueue.main.async {
                        self.addressSuggestions = predictions.compactMap { $0["description"] as? String }
                    }
                }
            } catch {
                print("Erreur de parsing JSON : \(error.localizedDescription)")
            }
        }.resume()
    }

}
