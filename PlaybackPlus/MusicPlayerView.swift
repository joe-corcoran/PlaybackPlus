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
    @State private var pauseTime: TimeInterval? = nil
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
        
        // Snippets list
        List(song.snippets.indices, id: \.self) { index in
            HStack {
                VStack(alignment: .leading) {
                    Text("\(formatTimeInterval(song.snippets[index].startTime)) - \(formatTimeInterval(song.snippets[index].endTime))")
                    Text(song.snippets[index].name)
                        .font(.caption)
                }
                Spacer()
                Image(systemName: "backward.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.blue)
                    .onTapGesture {
                        restartSnippet(song.snippets[index])
                    }
                Image(systemName: song.snippets[index].isPlaying ? "pause.circle" : "play.circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.blue)
                    .onTapGesture {
                        toggleSnippetPlayback(song.snippets[index])
                    }
                Text("Edit Note")
                    .onTapGesture {
                        editingSnippet = song.snippets[index]
                        isShowingNoteEditor = true
                    }
            }
            .sheet(isPresented: $isShowingNoteEditor, onDismiss: {
                editingSnippet = nil
            }) {
                if let snippet = editingSnippet,
                   let snippetIndex = song.snippets.firstIndex(where: { $0.id == snippet.id }) {
                    NoteEditorView(note: $song.snippets[snippetIndex].note)
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
    
    
    private func restartSnippet(_ snippet: Snippet) {
        if let player = self.player {
            player.currentTime = snippet.startTime
            player.play()
        } else {
            do {
                self.player = try AVAudioPlayer(contentsOf: song.url)
                self.player.currentTime = snippet.startTime
                self.player.play()
            } catch {
                print("Failed to initialize player: \(error)")
            }
        }
    }


    private func togglePlayback() {
        ensurePlayerInitialized()
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

    private func ensurePlayerInitialized() {
        if player == nil {
            do {
                self.player = try AVAudioPlayer(contentsOf: song.url)
            } catch {
                print("Failed to initialize player: \(error)")
            }
        }
    }


    private func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
     private func toggleSnippetPlayback(_ snippet: Snippet) {
         ensurePlayerInitialized()
        if let index = song.snippets.firstIndex(where: { $0.id == snippet.id }) {
            // Toggle the isPlaying state of the snippet
            song.snippets[index].isPlaying.toggle()
            
            if song.snippets[index].isPlaying {
                // Initialize the player if necessary
                if player == nil {
                    do {
                        self.player = try AVAudioPlayer(contentsOf: song.url)
                    } catch {
                        print("Failed to initialize player: \(error)")
                        return
                    }
                }
                
                // Start playing the snippet
                player.currentTime = snippet.startTime
                player.play()
                
                // Schedule a timer to pause the player when the snippet ends
                timer = Timer.scheduledTimer(withTimeInterval: snippet.endTime - snippet.startTime, repeats: false) { _ in
                    if let player = self.player {
                        player.pause()
                    }
                    // Make sure to update the isPlaying state of the snippet
                    if let snippetIndex = self.song.snippets.firstIndex(where: { $0.id == snippet.id }) {
                        self.song.snippets[snippetIndex].isPlaying = false
                    }
                }
            } else {
                // Stop playing the snippet
                if let player = self.player {
                    player.pause()
                }
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
