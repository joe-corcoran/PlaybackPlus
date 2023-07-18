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
    @State var email: String = ""
    @State var password: String = ""
    
    var body: some View {
        VStack {
            TextField("Email", text: $email)
            SecureField("Password", text: $password)
            Button("Log in", action: {
                sessionManager.login(email: email, password: password)
            })
            Button("Sign up", action: {
                sessionManager.signup(email: email, password: password)
            })
        }
        .padding()
    }
}
