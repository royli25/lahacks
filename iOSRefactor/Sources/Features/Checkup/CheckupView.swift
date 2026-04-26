import SwiftUI

struct CheckupView: View {
    @StateObject private var viewModel: CheckupViewModel
    let onEndCall: () -> Void

    init(viewModel: CheckupViewModel, onEndCall: @escaping () -> Void) {
        self.onEndCall = onEndCall
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            NativeAvatarView(
                session: viewModel.uiState.session,
                statusMessage: viewModel.uiState.statusMessage,
                errorMessage: viewModel.uiState.errorMessage,
                isMuted: viewModel.uiState.isMuted
            )
            .frame(height: 320)
            .padding(.horizontal, 20)
            .padding(.top, 20)

            HStack(spacing: 12) {
                Button(viewModel.uiState.isMuted ? "Unmute" : "Mute") {
                    viewModel.toggleMute()
                }
                .buttonStyle(.bordered)

                Button(viewModel.uiState.isTranscriptionEnabled ? "Stop STT" : "Local STT") {
                    Task { await viewModel.toggleTranscriptCapture() }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.uiState.isProcessingTranscript && !viewModel.uiState.isTranscriptionEnabled)

                Button("Summary") {
                    Task { await viewModel.requestSummary() }
                }
                .buttonStyle(.bordered)

                Button("End Call", role: .destructive) {
                    Task {
                        await viewModel.endVisit()
                        onEndCall()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.top, 20)

            if viewModel.uiState.session == nil {
                Button {
                    Task { await viewModel.startVisit() }
                } label: {
                    if viewModel.uiState.isStartingSession {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Start Visit")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AmiyaPalette.purple)
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            if !viewModel.uiState.summaryText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.headline)
                    Text(viewModel.uiState.summaryText)
                        .foregroundStyle(AmiyaPalette.gray)

                    if !viewModel.uiState.nextSteps.isEmpty {
                        Text("Next Steps")
                            .font(.headline)
                            .padding(.top, 4)
                        ForEach(viewModel.uiState.nextSteps, id: \.self) { step in
                            Text("- \(step)")
                        }
                    }
                }
                .padding(20)
            }

            List(viewModel.transcript) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.speaker)
                        .font(.caption)
                        .foregroundStyle(AmiyaPalette.gray)
                    Text(entry.text)
                        .foregroundStyle(AmiyaPalette.dark)
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
        }
        .background(AmiyaPalette.background.ignoresSafeArea())
        .navigationTitle(viewModel.patientName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
