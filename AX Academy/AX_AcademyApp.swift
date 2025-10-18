//
//  AX_AcademyApp.swift
//  AX Academy
//
//  Created by Hoshiar Sher on 10/5/25.
//

import SwiftUI

@main
struct AX_AcademyApp: App {
    
    init() {
        setupDependencies()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    /// Registers all app dependencies in the DependencyContainer
    private func setupDependencies() {
        let container = DependencyContainer.shared
        
        // Register content provider
        container.register(ContentProviding.self) {
            BundledJSONContentProvider()
        }
        
        // Analytics and persistence are already registered by default in DependencyContainer
    }
}
