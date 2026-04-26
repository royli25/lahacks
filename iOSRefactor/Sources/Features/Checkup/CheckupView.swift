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
                .disabled(viewModel.uiState.session == nil)

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
            Spacer()
        }
        .background(AmiyaPalette.background.ignoresSafeArea())
        .navigationTitle(viewModel.patientName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
