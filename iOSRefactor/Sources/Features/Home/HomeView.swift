import SwiftUI

struct HomeView: View {
    let onStartCheckup: (String) -> Void
    let onViewDashboard: () -> Void

    @State private var patientName = ""
    @State private var showError = false

    var body: some View {
        AmiyaScreen {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Amiya")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundStyle(AmiyaPalette.dark)

                        Text("Your AI Health Companion")
                            .foregroundStyle(AmiyaPalette.gray)
                    }
                    .padding(.top, 64)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Start a Checkup")
                            .font(.title2.bold())
                            .foregroundStyle(AmiyaPalette.dark)

                        Text("Connect with an AI doctor for a personalized health consultation.")
                            .foregroundStyle(AmiyaPalette.gray)
                            .fixedSize(horizontal: false, vertical: true)

                        TextField("Enter your full name", text: $patientName)
                            .textFieldStyle(.roundedBorder)

                        if showError {
                            Text("Please enter your name.")
                                .font(.footnote)
                                .foregroundStyle(.red)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button {
                            let trimmed = patientName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else {
                                showError = true
                                return
                            }
                            showError = false
                            onStartCheckup(trimmed)
                        } label: {
                            Text("Begin Checkup")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AmiyaPalette.purple)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AmiyaPalette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 24)

                    Button("View past checkups", action: onViewDashboard)
                        .foregroundStyle(AmiyaPalette.gray)
                        .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
