import Foundation

final class AppDependencies {
    let environment: AppEnvironment
    let backendService: any BackendServiceProtocol
    let liveAvatarService: any LiveAvatarSessionServiceProtocol

    init(environment: AppEnvironment) {
        self.environment = environment
        self.backendService = BackendAPIClient(environment: environment)
        self.liveAvatarService = LiveAvatarAPIClient(environment: environment)
    }
}

