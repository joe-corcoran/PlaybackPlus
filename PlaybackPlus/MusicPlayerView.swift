//
//  MusicPlayerView.swift
//  PlaybackPlus
//
//  Created by Joe Corcoran on 7/10/23.
//comment for initial commit
import SwiftUI
import AVFoundation

struct MusicPlayerView: View {
    @State var song: Song
    @Binding var songs: [Song]
    @State private var isShowingNoteEditor = false
     @State private var editingSnippet: Snippet? = nil

    @State private var player: AVAudioPlayer!
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0 {
        didSet {
            if !isScrubbing {
                startTime = currentTime
            }
        }
    }
    @State private var timer: Timer? = nil
    @State private var duration: TimeInterval = 0
    @State private var startTime: TimeInterval = 0
    @State private var endTime: TimeInterval = 0
    @State private var isScrubbing = false
    @State private var isShowingSaveSnippetPopup = false
    @State private var snippetName: String = ""
    
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        VStack {
            Text(song.url.lastPathComponent)
            Button(isPlaying ? "Pause" : "Play", action: togglePlayback)
            Text(String(format: "%02d:%02d", Int(currentTime)/60, Int(currentTime)%60))
            Slider(value: $currentTime, in: 0...duration, onEditingChanged: scrub)
            
            // Start and end sliders
            HStack {
                Text(String(format: "%02d:%02d", Int(startTime)/60, Int(startTime)%60))
                Slider(value: $startTime, in: 0...duration) { editing in
                    if editing {
                        isScrubbing = true
                    } else {
                        isScrubbing = false
                    }
                    if startTime >= endTime {
                        endTime = startTime + 1
                    }
                }
                Text(String(format: "%02d:%02d", Int(endTime)/60, Int(endTime)%60))
                Slider(value: $endTime, in: 0...duration) { _ in
                    if endTime <= startTime {
                        startTime = endTime - 1
                    }
                }
            }
            
            // Save button
            Button("Save Snippet", action: {
                isShowingSaveSnippetPopup = true
            })
            .padding()
            .sheet(isPresented: $isShowingSaveSnippetPopup) {
                VStack {
                    TextField("Snippet Name", text: $snippetName)
                        .padding()
                    Button("Save", action: {
                        saveSnippet()
                        isShowingSaveSnippetPopup = false
                    })
                    .padding()
                }
            }
        }
        
        List(song.snippets) { snippet in
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(formatTimeInterval(snippet.startTime)) - \(formatTimeInterval(snippet.endTime))")
                        Text(snippet.name)
                            .font(.caption)
                    }
                    Spacer()
                    Button(action: {
                        editingSnippet = snippet
                        isShowingNoteEditor = true
                    }) {
                        Text("Edit Note")
                    }
                    .sheet(isPresented: $isShowingNoteEditor, onDismiss: {
                        editingSnippet = nil
                    }) {
                        if let snippet = editingSnippet,
                           let index = song.snippets.firstIndex(where: { $0.id == snippet.id }) {
                            NoteEditorView(note: $song.snippets[index].note)
                        }
                    }
                }
            }

        
        .onAppear {
            do {
                self.player = try AVAudioPlayer(contentsOf: song.url)
                self.duration = self.player.duration
                self.endTime = self.player.duration
            } catch {
                print("Failed to initialize player: \(error)")
            }
            song.url.stopAccessingSecurityScopedResource()
        }
        .onDisappear {
            player.stop()
            timer?.invalidate()
            timer = nil
            if let index = songs.firstIndex(where: { $0.id == song.id }) {
                songs[index] = song
            }
        }
    }
    
    
    
    private func togglePlayback() {
        isPlaying.toggle()
        
        if isPlaying {
            player.play()
            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                guard !isScrubbing else { return }
                self.currentTime = self.player.currentTime
                
                if self.currentTime >= self.endTime {
                    self.player.currentTime = self.startTime
                }
            }
        } else {
            player.pause()
            timer?.invalidate()
            timer = nil
        }
    }
    
    
    
    private func scrub(isScrubbing: Bool) {
        if isScrubbing {
            self.isScrubbing = true
            player.currentTime = currentTime
            player.pause()
        } else {
            self.isScrubbing = false
            player.currentTime = currentTime
            if isPlaying {
                player.play()
            }
        }
    }
    
    private func saveSnippet() {
        guard startTime < endTime else { return }
        
        let snippet = Snippet(startTime: startTime, endTime: endTime, name: snippetName, note: "")
        song.snippets.append(snippet)
        
        startTime = 0
        endTime = duration
        snippetName = ""
    }


    private func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func toggleSnippetPlayback(_ snippet: Snippet) {
        if let index = song.snippets.firstIndex(where: { $0.id == snippet.id }) {
            // Toggle the isPlaying state of the snippet
            song.snippets[index].isPlaying.toggle()
            
            if song.snippets[index].isPlaying {
                // Start playing the snippet
                player.currentTime = snippet.startTime
                player.play()
                
                // Schedule a timer to pause the player when the snippet ends
                timer = Timer.scheduledTimer(withTimeInterval: snippet.endTime - snippet.startTime, repeats: false) { _ in
                    self.player.pause()
                    // Make sure to update the isPlaying state of the snippet
                    if let snippetIndex = self.song.snippets.firstIndex(where: { $0.id == snippet.id }) {
                        self.song.snippets[snippetIndex].isPlaying = false
                    }
                }
            } else {
                // Stop playing the snippet
                player.pause()
                timer?.invalidate()
                timer = nil
            }
        }
    }
}

struct NoteEditorView: View {
    @Binding var note: String
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            TextEditor(text: $note)
            Button("Done", action: {
                self.presentationMode.wrappedValue.dismiss()
            })
            .padding()
        }
        .padding()
    }
}

/*struct MusicPlayerView_Previews: PreviewProvider {
    static var previews: some View {
        let snippet = Snippet(startTime: 0, endTime: 100, name: "Sample Snippet")
        let song = Song(id: UUID(), url: URL(string: "https://example.com/audio.mp3")!, snippets: [snippet], songName: "Sample Song")
        var songs = [song]

        return MusicPlayerView(song: song, songs: .constant(songs))
    }
}




*/

//test

//test
