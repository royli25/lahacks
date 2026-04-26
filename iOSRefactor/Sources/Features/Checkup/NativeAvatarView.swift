import SwiftUI

#if canImport(LiveKit)
@preconcurrency import LiveKit

struct NativeAvatarView: View {
    let session: LiveAvatarSessionPayload?
    let statusMessage: String
    let errorMessage: String?
    let isMuted: Bool

    @StateObject private var roomContext = RoomContext()

    var body: some View {
        ZStack {
            if let track = roomContext.firstRemoteVideoTrack {
                LiveKitVideoView(track: track)
            } else {
                placeholderView
            }
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .task(id: session?.sessionID) {
            if let session,
               let url = session.livekitURL,
               let token = session.livekitClientToken {
                await roomContext.connect(url: url, token: token, microphoneEnabled: !isMuted)
            } else {
                await roomContext.disconnect()
            }
        }
        .task(id: isMuted) {
            guard session != nil else { return }
            await roomContext.setMicrophone(enabled: !isMuted)
        }
        .onDisappear {
            Task { await roomContext.disconnect() }
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

                Text(session == nil ? "Avatar not started" : "Connecting to doctor...")
                    .font(.headline)
                    .foregroundStyle(.white)

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

final class RoomContext: NSObject, ObservableObject {
    private lazy var room = Room(delegate: self)

    @Published var firstRemoteVideoTrack: VideoTrack?
    @Published var isMicrophoneEnabled = false

    func connect(url: String, token: String, microphoneEnabled: Bool) async {
        do {
            try await room.connect(url: url, token: token)
            await setMicrophone(enabled: microphoneEnabled)
        } catch {
            print("[LiveKit] connect error: \(error)")
        }
    }

    func setMicrophone(enabled: Bool) async {
        do {
            try await room.localParticipant.setMicrophone(enabled: enabled)
            await MainActor.run {
                isMicrophoneEnabled = enabled
            }
        } catch {
            await MainActor.run {
                isMicrophoneEnabled = false
            }
            print("[LiveKit] microphone error: \(error)")
        }
    }

    func disconnect() async {
        await setMicrophone(enabled: false)
        await room.disconnect()
        await MainActor.run {
            firstRemoteVideoTrack = nil
            isMicrophoneEnabled = false
        }
    }
}

extension RoomContext: RoomDelegate {
    func room(
        _ room: Room,
        participant: RemoteParticipant,
        didSubscribeTrack publication: RemoteTrackPublication
    ) {
        guard let track = publication.track as? VideoTrack else { return }
        DispatchQueue.main.async { [weak self] in
            self?.firstRemoteVideoTrack = track
        }
    }

    func room(
        _ room: Room,
        participant: RemoteParticipant,
        didUnsubscribeTrack publication: RemoteTrackPublication
    ) {
        guard publication.track is VideoTrack else { return }
        DispatchQueue.main.async { [weak self] in
            self?.firstRemoteVideoTrack = nil
        }
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

                Text(session == nil ? "Avatar not started" : "LiveKit unavailable")
                    .font(.headline)
                    .foregroundStyle(.white)

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
