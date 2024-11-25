import SwiftUI

class DynamicAppConfig: ObservableObject {
    
    @AppStorage("alertThreshold") var alertThreshold: Int = 15
    
    static let shared = DynamicAppConfig()
    
    @Published var showSorting: Bool {
        didSet {
            UserDefaults.standard.set(showSorting, forKey: "showSorting")
        }
    }
    @Published var showProductFilter: Bool {
        didSet {
            UserDefaults.standard.set(showProductFilter, forKey: "showProductFilter")
        }
    }
    
    private init() {
        self.showSorting = UserDefaults.standard.bool(forKey: "showSorting")
        self.showProductFilter = UserDefaults.standard.bool(forKey: "showProductFilter")
    }
}
