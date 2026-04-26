import Foundation

enum AppRoute: Hashable {
    case doctorSelection(patientName: String)
    case phoneEntry(patientName: String, doctor: DoctorProfile)
    case dashboard(uid: String, patientName: String, doctorName: String)
    case checkup(uid: String, patientName: String, doctor: DoctorProfile)
    case auth
}

