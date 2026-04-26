import Foundation

enum AppRoute: Hashable {
    case doctorSelection(patientName: String)
    case checkup(patientName: String, doctor: DoctorProfile)
}
