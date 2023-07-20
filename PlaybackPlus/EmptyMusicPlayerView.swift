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
    let documentID: String  // Add this line
    var url: URL
    var snippets: [Snippet]
}

struct Snippet: Identifiable, Codable, Equatable {
    let id: UUID
    let startTime: TimeInterval
    let endTime: TimeInterval
    let name: String
    var isPlaying: Bool
    var note: String
    var imageUrl: String  // Add imageUrl property

    // Standard initializer
    init(id: UUID = UUID(), startTime: TimeInterval, endTime: TimeInterval, name: String, isPlaying: Bool = false, note: String = "", imageUrl: String = "") {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.name = name
        self.isPlaying = isPlaying
        self.note = note
        self.imageUrl = imageUrl  // Initialize imageUrl
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
                        let newSong = Song(documentID: UUID().uuidString, url: newValue, snippets: [])
                        songs.append(newSong)
                        playerViewModel.selectSong(newSong)
                    }
                }
                
                List {
                    ForEach(songs) { song in
                        Button(action: {
                            playerViewModel.selectSong(song)
                        }) {
                            Text(song.url.lastPathComponent)
                        }
                    }
                    .onDelete(perform: deleteSongs)
                }
                .navigationBarTitle("Music Player", displayMode: .inline)
                .navigationBarItems(trailing: Button("Logout", action: logout))
                .onAppear {
                    loadSongs()
                }
            }
            .sheet(item: $playerViewModel.selectedSong) { song in
                MusicPlayerView(song: song, songs: $songs)
            }
        }
    }
    
    private func deleteSongs(at offsets: IndexSet) {
        offsets.forEach { index in
            let song = songs[index]
            // Delete the song from Firestore
            guard let userId = Auth.auth().currentUser?.uid else {
                return
            }
            let songDocumentRef = firestore.collection("users").document(userId).collection("songs").document(song.documentID)
            songDocumentRef.delete() { error in
                if let error = error {
                    print("Failed to delete song: \(error)")
                    return
                }
                
                // Then remove it from the local array
                songs.remove(at: index)
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

            DispatchQueue.main.async { // Update songs array on the main queue
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
                            let note = snippetDict["note"] as? String,
                            let imageUrl = snippetDict["imageUrl"] as? String
                        else {
                            return nil
                        }

                        return Snippet(
                            id: id,
                            startTime: startTime,
                            endTime: endTime,
                            name: name,
                            isPlaying: isPlaying,
                            note: note,
                            imageUrl: imageUrl
                        )
                    }

                    return Song(documentID: document.documentID, url: url, snippets: snippets) // use documentID
                }
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
