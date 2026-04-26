import SwiftUI

@main
struct AmiyaHealthApp: App {
    @StateObject private var coordinator: AppCoordinator

    init() {
        let environment = AppEnvironment.current()
        let dependencies = AppDependencies(environment: environment)
        _coordinator = StateObject(wrappedValue: AppCoordinator(dependencies: dependencies))
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinatorView()
                .environmentObject(coordinator)
        }
    }
}

