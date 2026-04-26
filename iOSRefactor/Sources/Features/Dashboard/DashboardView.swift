import SwiftUI

struct DashboardView: View {
    let uid: String
    let patientName: String
    let doctorName: String
    let onStartCheckup: (DoctorProfile) -> Void

    private let sampleHistory: [CheckupRecord] = [
        CheckupRecord(
            id: "1",
            date: "April 24, 2026",
            duration: "12 min",
            status: "completed",
            doctorName: "Dr. Carol Lee",
            summary: "Patient reported mild fatigue and occasional headaches. Recommended hydration and follow-up in two weeks.",
            transcript: [
                TranscriptEntry(speaker: "Doctor", text: "Hello! How are you feeling today?"),
                TranscriptEntry(speaker: "Patient", text: "I've been feeling a bit tired lately.")
            ],
            nextSteps: [
                "Drink 8 glasses of water daily",
                "Follow up in 2 weeks",
                "Track headache frequency"
            ]
        )
    ]

    var body: some View {
        AmiyaScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(patientName)
                            .font(.largeTitle.bold())
                            .foregroundStyle(AmiyaPalette.dark)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Patient Dashboard - UID: \(uid)")
                            .foregroundStyle(AmiyaPalette.gray)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Start New Checkup")
                                .font(.headline)
                                .foregroundStyle(AmiyaPalette.dark)
                            Text("With \(doctorName)")
                                .foregroundStyle(AmiyaPalette.gray)
                        }
                        Spacer()
                        Button("Begin") {
                            let doctor = DoctorDirectory.resolveProfile(for: doctorName) ?? DoctorDirectory.profiles[0]
                            onStartCheckup(doctor)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AmiyaPalette.purple)
                    }
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 24)

                    Text("Past Checkups")
                        .font(.headline)
                        .foregroundStyle(AmiyaPalette.dark)
                        .padding(.horizontal, 24)

                    ForEach(sampleHistory) { record in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(record.date)
                                .font(.headline)
                                .foregroundStyle(AmiyaPalette.dark)
                            Text(record.summary)
                                .foregroundStyle(AmiyaPalette.gray)
                                .fixedSize(horizontal: false, vertical: true)
                            if !record.nextSteps.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(record.nextSteps, id: \.self) { step in
                                        Text("- \(step)")
                                            .foregroundStyle(AmiyaPalette.dark)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 24)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
