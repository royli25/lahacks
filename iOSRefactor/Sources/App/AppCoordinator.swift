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

    func showPhoneEntry(patientName: String, doctor: DoctorProfile) {
        path.append(.phoneEntry(patientName: patientName, doctor: doctor))
    }

    func showDashboard(uid: String, patientName: String, doctorName: String) {
        path.append(.dashboard(uid: uid, patientName: patientName, doctorName: doctorName))
    }

    func replaceTop(with route: AppRoute) {
        if path.isEmpty {
            path = [route]
        } else {
            path[path.count - 1] = route
        }
    }

    func showCheckup(uid: String, patientName: String, doctor: DoctorProfile) {
        path.append(.checkup(uid: uid, patientName: patientName, doctor: doctor))
    }

    func showAuth() {
        path.append(.auth)
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
                },
                onViewDashboard: {
                    coordinator.showAuth()
                }
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .doctorSelection(let patientName):
                    DoctorSelectionView(
                        patientName: patientName,
                        onDoctorSelected: { doctor in
                            coordinator.showPhoneEntry(patientName: patientName, doctor: doctor)
                        }
                    )
                case .phoneEntry(let patientName, let doctor):
                    PhoneEntryView(
                        patientName: patientName,
                        doctor: doctor,
                        viewModel: PhoneEntryViewModel(backendService: coordinator.dependencies.backendService),
                        onRegistered: { uid in
                            coordinator.showCheckup(uid: uid, patientName: patientName, doctor: doctor)
                        }
                    )
                case .dashboard(let uid, let patientName, let doctorName):
                    DashboardView(
                        uid: uid,
                        patientName: patientName,
                        doctorName: doctorName,
                        onStartCheckup: { doctor in
                            coordinator.showCheckup(uid: uid, patientName: patientName, doctor: doctor)
                        }
                    )
                case .checkup(let uid, let patientName, let doctor):
                    CheckupView(
                        viewModel: CheckupViewModel(
                            uid: uid,
                            patientName: patientName,
                            doctor: doctor,
                            backendService: coordinator.dependencies.backendService,
                            liveAvatarService: coordinator.dependencies.liveAvatarService
                        ),
                        onEndCall: {
                            coordinator.resetToHome()
                        }
                    )
                case .auth:
                    AuthView(
                        onSignedIn: { uid, name, doctorName in
                            coordinator.replaceTop(with: .dashboard(uid: uid, patientName: name, doctorName: doctorName))
                        }
                    )
                }
            }
        }
    }
}
