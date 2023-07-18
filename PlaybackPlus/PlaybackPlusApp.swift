//
//  PlaybackPlusApp.swift
//  PlaybackPlus
//
//  Created by Joe Corcoran on 7/10/23.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()

    return true
  }
}

@main
struct PlaybackPlusApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
 
    
    var body: some Scene {
        WindowGroup {
            EmptyMusicPlayerView()
        }
    }
}

//test

//test
