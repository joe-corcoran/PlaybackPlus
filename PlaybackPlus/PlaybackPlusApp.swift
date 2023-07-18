//
//  PlaybackPlusApp.swift
//  PlaybackPlus
//
//  Created by Joe Corcoran on 7/10/23.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

class SessionManager: ObservableObject {
    @Published var isLoggedIn = false
    
    init() {
        isLoggedIn = Auth.auth().currentUser != nil
    }
    
    func login(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                print("Failed to log in: \(error)")
            } else {
                self?.isLoggedIn = true
            }
        }
    }

    func signup(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            if let error = error {
                print("Failed to sign up: \(error)")
            } else {
                self?.isLoggedIn = true
            }
        }
    }
}


@main
struct PlaybackPlusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var sessionManager = SessionManager()

    var body: some Scene {
        WindowGroup {
            if sessionManager.isLoggedIn {
                EmptyMusicPlayerView()
            } else {
                LoginView().environmentObject(sessionManager)
            }
        }
    }
}

//test

//test
