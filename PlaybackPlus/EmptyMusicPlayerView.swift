//
//  EmptyMusicPlayerView.swift
//  PlaybackPlus
//
//  Created by Joe Corcoran on 7/10/23.
//import SwiftUI

import SwiftUI
import AVFoundation
import MediaPlayer
import Firebase
import FirebaseFirestore
import FirebaseAuth
import FirebaseAnalytics

struct Song: Identifiable, Codable {
    let id = UUID()
    var url: URL
    var snippets: [Snippet]
}

struct Snippet: Identifiable, Codable {
    let id: UUID
    let startTime: TimeInterval
    let endTime: TimeInterval
    let name: String
    var isPlaying: Bool
    var note: String

    // Standard initializer
    init(id: UUID = UUID(), startTime: TimeInterval, endTime: TimeInterval, name: String, isPlaying: Bool = false, note: String = "") {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.name = name
        self.isPlaying = isPlaying
        self.note = note
    }
}

class MusicPlayerViewModel: ObservableObject {
    @Published var selectedSong: Song?
    @Published var isPresented = false

    func selectSong(_ song: Song) {
        selectedSong = song
        isPresented = true
    }
}
struct EmptyMusicPlayerView: View {
    @State private var fileURL: URL?
    @State private var showDocumentPicker = false
    @State private var songs: [Song] = []
    @StateObject private var playerViewModel = MusicPlayerViewModel()

    @EnvironmentObject var sessionManager: SessionManager
    private var firestore: Firestore = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                Text("No song loaded")
                Button("Load song") {
                    showDocumentPicker = true
                }
                .sheet(isPresented: $showDocumentPicker) {
                    DocumentPicker(fileURL: $fileURL, supportedTypes: [.mp3, .wav])
                }
                .onChange(of: fileURL) { newValue in
                    if let newValue = newValue {
                        let newSong = Song(url: newValue, snippets: [])
                        songs.append(newSong)
                        playerViewModel.selectSong(newSong)
                    }
                }

                List(songs) { song in
                    Button(action: {
                        playerViewModel.selectSong(song)
                    }) {
                        Text(song.url.lastPathComponent)
                    }
                }
            }
            .navigationBarTitle("Music Player", displayMode: .inline)
            .navigationBarItems(trailing: Button("Logout", action: logout))
            .onAppear {
                loadSongs()
            }
        }
        .sheet(isPresented: $playerViewModel.isPresented) {
            if let selectedSong = playerViewModel.selectedSong {
                MusicPlayerView(song: selectedSong, songs: $songs)
            }
        }
    }

    private func logout() {
        do {
            try Auth.auth().signOut()
            // Optional: Perform any additional logout-related actions
            sessionManager.isLoggedIn = false
        } catch {
            print("Error signing out: \(error)")
        }
    }


 private func loadSongs() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }

        let songsCollectionRef = firestore.collection("users").document(userId).collection("songs")
        songsCollectionRef.getDocuments { snapshot, error in
            if let error = error {
                print("Failed to fetch songs: \(error)")
                return
            }

            guard let documents = snapshot?.documents else {
                return
            }

            songs = documents.compactMap { document in
                guard
                    let urlString = document.data()["url"] as? String,
                    let url = URL(string: urlString),
                    let snippetsData = document.data()["snippets"] as? [[String: Any]]
                else {
                    return nil
                }

                let snippets = snippetsData.compactMap { snippetDict -> Snippet? in
                    guard
                        let idString = snippetDict["id"] as? String,
                        let id = UUID(uuidString: idString),
                        let startTime = snippetDict["startTime"] as? TimeInterval,
                        let endTime = snippetDict["endTime"] as? TimeInterval,
                        let name = snippetDict["name"] as? String,
                        let isPlaying = snippetDict["isPlaying"] as? Bool,
                        let note = snippetDict["note"] as? String
                    else {
                        return nil
                    }

                    return Snippet(
                        id: id,
                        startTime: startTime,
                        endTime: endTime,
                        name: name,
                        isPlaying: isPlaying,
                        note: note
                    )
                }

                return Song(url: url, snippets: snippets)
            }
        }
    }

}


struct EmptyMusicPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyMusicPlayerView()
    }
}

//test

//test
