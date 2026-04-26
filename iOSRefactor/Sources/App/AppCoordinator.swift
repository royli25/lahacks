import SwiftUI

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path: [AppRoute] = []

    let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func showDoctorSelection(patientName: String) {
        path.append(.doctorSelection(patientName: patientName))
    }

    func showCheckup(patientName: String, doctor: DoctorProfile) {
        path.append(.checkup(patientName: patientName, doctor: doctor))
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func resetToHome() {
        path.removeAll()
    }
}

struct AppCoordinatorView: View {
    @EnvironmentObject private var coordinator: AppCoordinator

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            HomeView(
                onStartCheckup: { patientName in
                    coordinator.showDoctorSelection(patientName: patientName)
                }
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .doctorSelection(let patientName):
                    DoctorSelectionView(
                        patientName: patientName,
                        onDoctorSelected: { doctor in
                            coordinator.showCheckup(patientName: patientName, doctor: doctor)
                        }
                    )
                case .checkup(let patientName, let doctor):
                    CheckupView(
                        viewModel: CheckupViewModel(
                            patientName: patientName,
                            doctor: doctor,
                            liveAvatarService: coordinator.dependencies.liveAvatarService
                        ),
                        onEndCall: {
                            coordinator.resetToHome()
                        }
                    )
                }
            }
        }
    }
}
