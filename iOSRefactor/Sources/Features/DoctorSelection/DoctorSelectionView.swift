import SwiftUI

struct DoctorSelectionView: View {
    let patientName: String
    let onDoctorSelected: (DoctorProfile) -> Void

    @State private var selectedDoctorID: String?

    var body: some View {
        AmiyaScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Choose Your Doctor")
                        .font(.largeTitle.bold())
                        .foregroundStyle(AmiyaPalette.dark)
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Hi \(patientName)! Select a doctor for your checkup.")
                        .foregroundStyle(AmiyaPalette.gray)
                        .padding(.horizontal, 24)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 16) {
                        ForEach(DoctorDirectory.profiles) { doctor in
                            Button {
                                selectedDoctorID = doctor.id
                            } label: {
                                HStack(spacing: 16) {
                                    Circle()
                                        .fill(selectedDoctorID == doctor.id ? AmiyaPalette.purple : Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .overlay(Image(systemName: "person.fill").foregroundStyle(AmiyaPalette.dark))

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(doctor.displayName)
                                            .font(.headline)
                                            .foregroundStyle(AmiyaPalette.dark)
                                        Text(doctor.specialty)
                                            .foregroundStyle(AmiyaPalette.gray)
                                    }

                                    Spacer()
                                }
                                .padding()
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(selectedDoctorID == doctor.id ? AmiyaPalette.purple : Color.clear, lineWidth: 2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                    Button("Continue with Selected Doctor") {
                        guard let selectedDoctor = DoctorDirectory.profiles.first(where: { $0.id == selectedDoctorID }) else {
                            return
                        }
                        onDoctorSelected(selectedDoctor)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AmiyaPalette.purple)
                    .disabled(selectedDoctorID == nil)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    .padding(.top, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

