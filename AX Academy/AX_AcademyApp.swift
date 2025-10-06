//
//  AX_AcademyApp.swift
//  AX Academy
//
//  Created by Hoshiar Sher on 10/5/25.
//

import SwiftUI
import Core

@main
struct AX_AcademyApp: App {
    var body: some Scene {
        WindowGroup {
            KindergartenCoordinator(
                       contentProvider: StaticContentProvider(),
                       analytics: DependencyContainer.shared.resolve(AnalyticsLogging.self),
                       persistence: DependencyContainer.shared.resolve(Persistence.self)
                   ).start()
        }
    }
}
