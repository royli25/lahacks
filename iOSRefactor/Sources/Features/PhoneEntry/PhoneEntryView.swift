import SwiftUI

struct PhoneEntryView: View {
    let patientName: String
    let doctor: DoctorProfile
    @StateObject private var viewModel: PhoneEntryViewModel
    let onRegistered: (String) -> Void

    init(
        patientName: String,
        doctor: DoctorProfile,
        viewModel: PhoneEntryViewModel,
        onRegistered: @escaping (String) -> Void
    ) {
        self.patientName = patientName
        self.doctor = doctor
        self.onRegistered = onRegistered
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        AmiyaScreen {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Enter Phone Number")
                        .font(.largeTitle.bold())
                        .foregroundStyle(AmiyaPalette.dark)
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("We'll send your appointment link via SMS.")
                        .foregroundStyle(AmiyaPalette.gray)
                        .padding(.horizontal, 24)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Appointment Summary")
                            .font(.headline)
                            .foregroundStyle(AmiyaPalette.dark)
                        summaryRow(label: "Patient", value: patientName)
                        summaryRow(label: "Doctor", value: doctor.agentName)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 24)

                    TextField("(555) 555-5555", text: Binding(
                        get: { format(viewModel.phoneDigits) },
                        set: { value in
                            viewModel.phoneDigits = String(value.filter { $0.isNumber }.prefix(10))
                        }
                    ))
                    .keyboardType(.phonePad)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 24)

                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 24)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Button {
                        Task {
                            if let uid = await viewModel.register(patientName: patientName, doctor: doctor) {
                                onRegistered(uid)
                            }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(AmiyaPalette.dark)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Start Checkup")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AmiyaPalette.purple)
                    .disabled(viewModel.phoneDigits.count != 10 || viewModel.isLoading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text("\(label):")
                .foregroundStyle(AmiyaPalette.gray)
            Text(value)
                .foregroundStyle(AmiyaPalette.dark)
                .fontWeight(.medium)
        }
    }

    private func format(_ digits: String) -> String {
        let chars = Array(digits)
        var output = ""
        for (index, char) in chars.enumerated() {
            switch index {
            case 0: output += "(\(char)"
            case 3: output += ") \(char)"
            case 6: output += "-\(char)"
            default: output.append(char)
            }
        }
        return output
    }
}
