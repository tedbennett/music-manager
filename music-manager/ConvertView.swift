//
//  ConvertView.swift
//  music-manager
//
//  Created by Ted Bennett on 23/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI

struct ConvertView: View {
    enum ConversionState {
        case notStarted
        case notLoggedIn
        case invalidURL
        case targetSpotifyTrack
        case targetAppleMusicTrack
        case notAvailableSpotifyTrack
        case notAvailableAppleMusicTrack
    }
    
    @State var clipboardString: String?
    @State var clipboardTrack: Track?
    @State var targetTrack: Track?
    @State private var state: ConversionState = .notStarted
    
    var spotifyManager = SpotifyManager.shared
    var appleMusicManager = AppleMusicManager.shared
    
    var body: some View {
        VStack {
            if state == .notStarted {
                Text("Working...")
            }
            else if state == .notLoggedIn {
                VStack {
                    Text("You are not logged in to both services").multilineTextAlignment(.center)
                    Text("You can log in on the 'Add Services' tab").font(.subheadline)
                        .multilineTextAlignment(.center)
                }
            }
            else if state == .invalidURL {
                VStack {
                    Text("Can't find music URL in your clipboard").padding(10)
                    Text("Copy an 'open.spotify.com' or 'music.apple.com song' link").font(.subheadline)
                        .multilineTextAlignment(.center)
                }.padding(15)
            }
            else {
                
                TrackView(track: self.clipboardTrack!)    
                if targetTrack != nil {
                    Button(action: {
                        UIApplication.shared.open(self.targetTrack!.url!)
                    }) {
                        if state == .targetAppleMusicTrack {
                            Text("Open in Apple Music?")
                        }
                        if state == .targetSpotifyTrack {
                            Text("Open in Spotify?")
                        }
                    }
                }
                if state == .notAvailableSpotifyTrack {
                    Text("Could not find track in Spotify")
                }
                if state == .notAvailableAppleMusicTrack {
                    Text("Could not find track in Apple Music")
                }
            }
        }.onAppear {
            self.state = .notStarted
            self.clipboardString = UIPasteboard.general.string
            self.checkURL()
        }
    }
    
    func checkURL() {
        if self.spotifyManager.authToken == nil || self.appleMusicManager.userToken == nil {
            self.state = .notLoggedIn
            return
        }
        
        if clipboardString != nil, let url = URL(string: clipboardString!) {
            if url.host == "open.spotify.com" {
                print(url.pathComponents)
                if url.pathComponents[1] == "track" {
                    spotifyManager.getIsrcID(id: url.lastPathComponent, completion: { track in
                        self.clipboardTrack = track
                        if track.isrcID != nil {
                            self.appleMusicManager.getTracksFromIsrcID(isrcs: [track.isrcID!], completion: { tracks in
                                if tracks[0] != nil {
                                    if tracks[0]!.url != nil {
                                        self.targetTrack = tracks[0]
                                        self.state = .targetAppleMusicTrack
                                    } else {
                                        self.state = .notAvailableAppleMusicTrack
                                    }
                                } else {
                                    self.state = .notAvailableAppleMusicTrack
                                }
                            })
                        } else {
                            self.state = .notAvailableAppleMusicTrack
                        }
                    })
                }
            } else if url.host == "music.apple.com" {
                let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
                if url.pathComponents[2] == "album" {
                    if let id = components?.queryItems?.first(where: { $0.name == "i"})?.value {
                        print(id)
                        appleMusicManager.getIsrcID(id: id, completion: { track in
                            self.clipboardTrack = track
                            if track.isrcID != nil {
                                self.spotifyManager.getTracksFromIsrcID(isrcs: [track.isrcID!], completion: { tracks in
                                    if tracks[0] != nil {
                                        if  tracks[0]!.url != nil {
                                            self.targetTrack = tracks[0]
                                            self.state = .targetSpotifyTrack
                                        } else {
                                            self.state = .notAvailableSpotifyTrack
                                        }
                                    } else {
                                        self.state = .notAvailableSpotifyTrack
                                    }
                                })
                            } else {
                                self.state = .notAvailableSpotifyTrack
                            }
                        })
                    }
                }
            } else {
                self.state = .invalidURL
                return
            }
        } else {
            self.state = .invalidURL
            return
        }
    }
}

struct ConvertView_Previews: PreviewProvider {
    static var previews: some View {
        ConvertView()
    }
}


struct TrackView: View {
    var track: Track
    
    var body: some View {
        VStack {
            if track.imageURL != nil {
                AsyncImage(url: track.imageURL!, placeholder: VStack {
                    Image(systemName: "ellipsis")
                    Text("Loading")
                    }, configuration: {
                        $0.resizable()
                }).frame(minWidth: 100, idealWidth: 300, maxWidth: 300, minHeight: 100, idealHeight: 300, maxHeight: 300, alignment: .center).padding(20)
                
            } else {
                VStack {
                    Image(systemName: "camera").frame(width: 300, height: 300, alignment: .center)
                    Text("Unable to find cover art")
                }
            }
            Text(track.name).font(.title).padding(15).multilineTextAlignment(.center)
            HStack {
                ForEach(track.artists, id:\.self) { artist in
                    Text(artist).font(.headline).padding(10)
                }
            }
            
        }
    }
}




