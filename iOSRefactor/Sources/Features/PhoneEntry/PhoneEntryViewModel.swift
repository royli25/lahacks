import Foundation

@MainActor
final class PhoneEntryViewModel: ObservableObject {
    @Published var phoneDigits = ""
    @Published var isLoading = false
    @Published var errorMessage = ""

    init(backendService: any BackendServiceProtocol) {
        _ = backendService
    }

    func register(patientName _: String, doctor _: DoctorProfile) async -> String? {
        guard phoneDigits.count == 10 else {
            errorMessage = "Please enter a valid 10-digit phone number."
            return nil
        }

        errorMessage = ""
        return "local-\(UUID().uuidString)"
    }
}

