import SwiftUI
#if canImport(LiveKit)
import LiveKit
import AVFoundation

struct NativeAvatarView: View {
    let session: LiveAvatarSessionPayload?
    let statusMessage: String
    let errorMessage: String?
    let isMuted: Bool

    @StateObject private var roomCtx = RoomContext()

    var body: some View {
        ZStack {
            if let track = roomCtx.firstRemoteVideoTrack {
                LiveKitVideoView(track: track)
            } else {
                placeholderView
            }
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        // Connect only after the user taps Start Visit; disconnect when session is cleared.
        .task(id: session?.sessionID) {
            if let s = session,
               let url = s.livekitURL,
               let token = s.livekitClientToken {
                await roomCtx.connect(url: url, token: token, microphoneEnabled: !isMuted)
            } else {
                await roomCtx.disconnect()
            }
        }
        .task(id: isMuted) {
            guard session != nil else { return }
            await roomCtx.setMicrophone(enabled: !isMuted)
        }
        .onDisappear {
            Task { await roomCtx.disconnect() }
        }
    }

    private var placeholderView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.07, green: 0.09, blue: 0.15),
                            Color(red: 0.05, green: 0.07, blue: 0.11)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 12) {
                Image(systemName: "video.bubble.left.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.white.opacity(0.85))

                if session != nil {
                    Text("Connecting to doctor...")
                        .font(.headline)
                        .foregroundStyle(.white)
                } else {
                    Text("Avatar not started")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.75))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.red.opacity(0.9))
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}

// UIViewRepresentable wrapper — LiveKit 2.x VideoView is a UIKit view, not SwiftUI.
private struct LiveKitVideoView: UIViewRepresentable {
    let track: VideoTrack

    func makeUIView(context: Context) -> VideoView {
        let view = VideoView()
        view.layoutMode = .fill
        return view
    }

    func updateUIView(_ uiView: VideoView, context: Context) {
        uiView.track = track
    }
}

@MainActor
final class RoomContext: NSObject, ObservableObject {
    private let room = Room()
    @Published var firstRemoteVideoTrack: VideoTrack?
    @Published var isMicrophoneEnabled = false

    override init() {
        super.init()
        room.add(delegate: self)
    }

    func connect(url: String, token: String, microphoneEnabled: Bool) async {
        do {
            try configureAudioSession()
            try await room.connect(url: url, token: token)
            await setMicrophone(enabled: microphoneEnabled)
        } catch {
            print("[LiveKit] connect error: \(error)")
        }
    }

    func setMicrophone(enabled: Bool) async {
        do {
            try await room.localParticipant.setMicrophone(enabled: enabled)
            isMicrophoneEnabled = enabled
        } catch {
            isMicrophoneEnabled = false
            print("[LiveKit] microphone error: \(error)")
        }
    }

    func disconnect() async {
        await setMicrophone(enabled: false)
        await room.disconnect()
        firstRemoteVideoTrack = nil
        isMicrophoneEnabled = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .voiceChat,
            options: [.allowBluetooth, .allowBluetoothA2DP, .defaultToSpeaker]
        )
        try session.setActive(true)
    }
}

extension RoomContext: RoomDelegate {
    nonisolated func room(
        _ room: Room,
        participant: RemoteParticipant,
        didSubscribeTrack publication: RemoteTrackPublication
    ) {
        guard let track = publication.track as? VideoTrack else { return }
        Task { @MainActor in self.firstRemoteVideoTrack = track }
    }

    nonisolated func room(
        _ room: Room,
        participant: RemoteParticipant,
        didUnsubscribeTrack publication: RemoteTrackPublication
    ) {
        guard publication.track is VideoTrack else { return }
        Task { @MainActor in self.firstRemoteVideoTrack = nil }
    }
}

#else

struct NativeAvatarView: View {
    let session: LiveAvatarSessionPayload?
    let statusMessage: String
    let errorMessage: String?
    let isMuted: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.07, green: 0.09, blue: 0.15),
                            Color(red: 0.05, green: 0.07, blue: 0.11)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            VStack(spacing: 12) {
                Image(systemName: "video.bubble.left.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.white.opacity(0.85))

                if session != nil {
                    Text("Connecting to doctor...")
                        .font(.headline)
                        .foregroundStyle(.white)
                } else {
                    Text("Avatar not started")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.75))

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.red.opacity(0.9))
                        .padding(.horizontal, 16)
                }
            }
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

#endif
