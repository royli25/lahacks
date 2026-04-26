import SwiftUI

struct AuthView: View {
    let onSignedIn: (String, String, String) -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var message = ""

    var body: some View {
        AmiyaScreen {
            VStack(spacing: 20) {
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AmiyaPalette.dark)

                Text(isSignUp ? "Stub auth flow for the Swift refactor." : "Use this screen as the auth integration entry point.")
                    .foregroundStyle(AmiyaPalette.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(24)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 24)

                if !message.isEmpty {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(AmiyaPalette.gray)
                }

                Button(isSignUp ? "Create Account" : "Sign In") {
                    message = isSignUp
                        ? "Account creation is still a placeholder. Wire Supabase or your chosen auth provider next."
                        : "Using demo sign-in route for the migration scaffold."

                    if !isSignUp {
                        onSignedIn("demo_uid", "Demo User", "Dr. Carol Lee")
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(AmiyaPalette.purple)
                .disabled(email.isEmpty || password.isEmpty)

                Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                    isSignUp.toggle()
                    message = ""
                }
                .foregroundStyle(AmiyaPalette.gray)

                Spacer()
            }
            .padding(.top, 48)
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

