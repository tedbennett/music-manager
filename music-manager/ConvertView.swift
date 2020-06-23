//
//  ConvertView.swift
//  music-manager
//
//  Created by Ted Bennett on 23/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI

struct ConvertView: View {
    @State var clipboardString: String?
    @State var isValidURL = false
    @State var clipboardTrack: Track?
    @State var targetTrack: Track?
    
    var spotifyManager = SpotifyManager.shared
    var appleMusicManager = AppleMusicManager.shared
    
    var body: some View {
        VStack {
            if clipboardTrack == nil && targetTrack == nil {
                Text(isValidURL ? self.clipboardString ?? "Clipboard empty" : "Invalid URL")
            }
            if clipboardTrack != nil {
                TrackView(track: clipboardTrack!)
            }
            if targetTrack != nil {
                Button(action: {
                    UIApplication.shared.open(URL(string: (self.targetTrack!.url)!)!)
                }) {
                    Text("Open in Apple Music?")
                }
            }
            
        }.onAppear {
            self.clipboardString = UIPasteboard.general.string
            self.isValidURL = self.checkURL()
            if self.isValidURL {
                
            }
        }
    }
    
    func checkURL() -> Bool {
        if clipboardString == nil {
            return false
        }
        guard let url = URL(string: clipboardString!) else {
            return false
        }
        if url.host == "open.spotify.com" {
            print(url.pathComponents)
            if url.pathComponents[1] == "track" {
                spotifyManager.getIsrcID(id: url.lastPathComponent, completion: { track in
                    self.clipboardTrack = track
                    if track.isrcID != nil {
                        self.appleMusicManager.getTracksFromIsrcID(isrcs: [track.isrcID!], completion: { tracks in
                            if URL(string: tracks[0].url ?? "") != nil {
                                self.targetTrack = tracks[0]
                            }
                        })
                    }
                })
            }
            return true
        } else if url.host == "music.apple.com" {
            return true
        }
        return false
    }
    
    func getUrl(){
        
    }
}

struct ConvertView_Previews: PreviewProvider {
    static var previews: some View {
        ConvertView()
    }
}


struct TrackView: View {
    var track: Track
    @State private var image: UIImage?
    
    var body: some View {
        VStack {
            if image != nil {
                Image(uiImage: image!)
            }
            Text(track.name).font(.title)
            HStack {
                ForEach(track.artists, id:\.self) { artist in
                    Text(artist.name).font(.headline)
                }
            }
            
        }.onAppear {
            self.downloadImage(from: URL(string:self.track.album.imageURL!)!, size: CGFloat(300))
        }
    }
    
    func downloadImage(from url: URL, size: CGFloat) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? url.lastPathComponent)
            DispatchQueue.main.async() {
                let image = UIImage(data: data)
                let scale: CGFloat = (image?.size.height)! / size
                self.image = UIImage(data: data, scale: scale)
            }
        }.resume()
    }
}

