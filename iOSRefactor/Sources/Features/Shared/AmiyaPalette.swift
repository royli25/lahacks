import SwiftUI

enum AmiyaPalette {
    static let dark = Color(red: 0.07, green: 0.08, blue: 0.13)
    static let gray = Color(red: 0.42, green: 0.45, blue: 0.50)
    static let purple = Color(red: 0.78, green: 0.67, blue: 0.98)
    static let card = Color.white
    static let background = LinearGradient(
        colors: [Color.white, Color(red: 0.95, green: 0.93, blue: 1.0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct AmiyaScreen<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            AmiyaPalette.background.ignoresSafeArea()
            content
        }
    }
}
