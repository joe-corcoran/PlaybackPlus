//
//  LoginView.swift
//  PlaybackPlus
//
//  Created by Joe Corcoran on 7/18/23.
//
import SwiftUI
import FirebaseAuth

struct LoginView: View {
    @EnvironmentObject var sessionManager: SessionManager
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            Button("Log in") {
                login()
            }
            Button("Sign up") {
                signup()
            }
        }
        .padding()
    }
    
    private func login() {
        sessionManager.login(email: email, password: password) { result in 
            switch result {
            case .success:
                // Handle successful login
                break
            case .failure(let error):
                // Handle login error
                print("Failed to log in: \(error.localizedDescription)")
            }
        }
    }
    
    private func signup() {
        sessionManager.signup(email: email, password: password) { result in
            switch result {
            case .success:
                // Handle successful signup
                break
            case .failure(let error):
                // Handle signup error
                print("Failed to sign up: \(error.localizedDescription)")
            }
        }
    }
}
