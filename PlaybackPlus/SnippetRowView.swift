//
//  SnippetRowView.swift
//  PlaybackPlus
//
//  Created by Joe Corcoran on 7/13/23.
//

import SwiftUI
import AVFoundation


struct SnippetRowView: View {
    let snippet: Snippet
    let player: AVAudioPlayer
    @Binding var snippets: [Snippet]

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(formatTimeInterval(snippet.startTime)) - \(formatTimeInterval(snippet.endTime))")
                Text(snippet.name)
                    .font(.caption)
            }

            Spacer()

            Button(action: {
                restartSnippet(snippet)
            }) {
                Image(systemName: "backward.fill")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.blue)
            }

            Button(action: {
                toggleSnippetPlayback(snippet)
            }) {
                Image(systemName: snippet.isPlaying ? "pause.circle" : "play.circle")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.blue)
            }
        }
    }

    private func formatTimeInterval(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func restartSnippet(_ snippet: Snippet) {
        guard snippet.endTime <= player.duration else { return }
        
        player.currentTime = snippet.startTime
        player.play()
        
        for index in snippets.indices {
            if snippets[index].id == snippet.id {
                snippets[index].isPlaying = true
            } else {
                snippets[index].isPlaying = false
            }
        }
    }
    
    private func toggleSnippetPlayback(_ snippet: Snippet) {
        if snippet.isPlaying {
            pauseSnippet(snippet)
        } else {
            playSnippet(snippet)
        }
    }
    
    private func playSnippet(_ snippet: Snippet) {
        guard snippet.endTime <= player.duration else { return }
        
        player.currentTime = snippet.startTime
        player.play()
        
        for index in snippets.indices {
            if snippets[index].id == snippet.id {
                snippets[index].isPlaying = true
            } else {
                snippets[index].isPlaying = false
            }
        }
    }
    
    private func pauseSnippet(_ snippet: Snippet) {
        for index in snippets.indices {
            if snippets[index].id == snippet.id {
                snippets[index].isPlaying = false
            }
        }
    }
}

//test

/*struct SnippetRowView_Previews: PreviewProvider {
    static let snippet = Snippet(startTime: 0, endTime: 10, name: "Sample Snippet")
    static let player = AVAudioPlayer()
    @State static var snippets = [snippet]

    static var previews: some View {
        SnippetRowView(snippet: snippet, player: player, snippets: $snippets)
    }
}
*/
//test
