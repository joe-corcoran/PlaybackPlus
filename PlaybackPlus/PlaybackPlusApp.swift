//
//  PlaybackPlusApp.swift
//  PlaybackPlus
//
//  Created by Joe Corcoran on 7/10/23.
//

import SwiftUI
import Firebase

@main
struct PlaybackPlusApp: App {
    
    init() {
          FirebaseApp.configure()
      }
    
    var body: some Scene {
        WindowGroup {
            EmptyMusicPlayerView()
        }
    }
}

//test

//test
