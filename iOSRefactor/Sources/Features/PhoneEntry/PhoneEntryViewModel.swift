import Foundation

@MainActor
final class PhoneEntryViewModel: ObservableObject {
    @Published var phoneDigits = ""
    @Published var isLoading = false
    @Published var errorMessage = ""

    private let backendService: any BackendServiceProtocol

    init(backendService: any BackendServiceProtocol) {
        self.backendService = backendService
    }

    func register(patientName: String, doctor: DoctorProfile) async -> String? {
        guard phoneDigits.count == 10 else {
            errorMessage = "Please enter a valid 10-digit phone number."
            return nil
        }

        isLoading = true
        errorMessage = ""

        defer { isLoading = false }

        do {
            let response = try await backendService.registerPatient(
                request: NewPatientRequest(
                    name: patientName,
                    phoneNumber: "+1\(phoneDigits)",
                    agentName: doctor.agentName
                )
            )
            return response.uid
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }
}

