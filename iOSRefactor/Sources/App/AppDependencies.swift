import Foundation

final class AppDependencies {
    let environment: AppEnvironment
    let liveAvatarService: any LiveAvatarSessionServiceProtocol

    init(environment: AppEnvironment) {
        self.environment = environment
        self.liveAvatarService = LiveAvatarAPIClient(environment: environment)
    }
}
