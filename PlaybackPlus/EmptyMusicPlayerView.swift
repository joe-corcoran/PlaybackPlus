//
//  EmptyMusicPlayerView.swift
//  PlaybackPlus
//
//  Created by Joe Corcoran on 7/10/23.
//import SwiftUI

import SwiftUI
import AVFoundation
import MediaPlayer

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



struct EmptyMusicPlayerView: View {
    @State private var fileURL: URL?
    @State private var showDocumentPicker = false
    @State private var navigateToPlayer = false
    @State private var songs: [Song] = []

    var body: some View {
        NavigationView{
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
                        navigateToPlayer = true
                    }
                }
                if navigateToPlayer, let song = songs.last {
                    NavigationLink(destination: MusicPlayerView(song: song, songs: $songs), isActive: $navigateToPlayer) {
                        EmptyView()
                    }
                }
                List(songs) { song in
                    NavigationLink(destination: MusicPlayerView(song: song, songs: $songs)) {
                        Text(song.url.lastPathComponent)
                    }
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
