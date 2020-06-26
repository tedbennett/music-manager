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
        case invalidURL
        case trackAvailable
        case trackNotAvailable
    }
    @Environment(\.verticalSizeClass) var sizeClass
    @State private var clipboardString: String?
    @State private var clipboardTrack: Track?
    @State private var targetTrack: Track?
    @State private var state: ConversionState = .notStarted
    @State private var showSearchModal = false
    
    @State private var targetServiceType: ServiceType?
    
    //var spotifyManager = SpotifyManager.shared
    //var appleMusicManager = AppleMusicManager.shared
    
    var body: some View {
        VStack {
            if state == .notStarted {
                Text("Working...")
            }
            else if state == .invalidURL {
                VStack {
                    Text("Can't find music URL in your clipboard").padding(10)
                    Text("Copy an 'open.spotify.com' or 'music.apple.com song' link").font(.subheadline)
                        .multilineTextAlignment(.center)
                }.padding(15)
            }
            else {
                if sizeClass == .compact {
                    HStack {
                        TrackImage()
                        TrackDetails()
                    }
                } else {
                    
                        TrackImage()
                        TrackDetails()
                    
                }
            }
        }.onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            self.state = .notStarted
            self.clipboardString = UIPasteboard.general.string
            self.checkURL()
        }
        .onAppear {
            self.state = .notStarted
            self.clipboardString = UIPasteboard.general.string
            self.checkURL()
        }
    }
    
    func TrackDetails() -> some View {
        VStack {
            Text(self.clipboardTrack!.name).font(.title).padding(15).multilineTextAlignment(.center)
            HStack {
                ForEach(self.clipboardTrack!.artists, id:\.self) { artist in
                    Text(artist).font(.headline).padding(10)
                }
            }
            if targetTrack != nil {
                Button(action: {
                    UIApplication.shared.open(self.targetTrack!.url!)
                }) {
                    Text("Open in \(serviceNames[self.targetServiceType!]!)")
                }.padding(10)
            }
            if state == .trackNotAvailable {
                Text("Could not find track in \(serviceNames[self.targetServiceType!]!)").padding(10)
                Button(action: {
                    self.showSearchModal.toggle()
                }) {
                    Text("Search in \(serviceNames[self.targetServiceType!]!)")
                }.sheet(isPresented: self.$showSearchModal) {
                    if self.targetServiceType! == .AppleMusic {
                        SearchView(searchTerm: self.clipboardTrack!.name, manager: AppleMusicManager.shared)
                    } else {
                        SearchView(searchTerm: self.clipboardTrack!.name, manager: SpotifyManager.shared)
                    }
                }
            }
        }
    }
    
    func TrackImage() -> some View {
        VStack {
            if self.clipboardTrack!.imageURL != nil {
                AsyncImage(url: self.clipboardTrack!.imageURL!, placeholder: VStack {
                    Image(systemName: "camera").frame(width: 100, height: 100)
                    }, configuration: {
                        $0.resizable()
                }).cornerRadius(10)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(minWidth: 100, idealWidth: 300, maxWidth: 300, minHeight: 100, idealHeight: 300, maxHeight: 300, alignment: .center).padding(20)
                
            } else {
                VStack {
                    Image(systemName: "camera").frame(width: 300, height: 300, alignment: .center)
                    Text("Unable to find cover art")
                }
            }
        }
    }
    
    func checkURL() {
        
        if clipboardString != nil, let url = URL(string: clipboardString!) {
            if url.host == "open.spotify.com" {
                self.targetServiceType = .AppleMusic
                if url.pathComponents[1] == "track" {
                    SpotifyManager.shared.getIsrcID(id: url.lastPathComponent, completion: { track in
                        self.clipboardTrack = track
                        if track.isrcID != nil {
                            AppleMusicManager.shared.getTracksFromIsrcID(isrcs: [track.isrcID!], completion: { tracks in
                                if !tracks.isEmpty {
                                    if tracks[0].url != nil {
                                        self.targetTrack = tracks[0]
                                        self.state = .trackAvailable
                                    } else {
                                        self.state = .trackNotAvailable
                                    }
                                } else {
                                    AppleMusicManager.shared.getSearchResults(for: self.clipboardTrack!.name) { tracks in
                                        for track in tracks {
                                            if track.name == self.clipboardTrack!.name && track.artists[0] == self.clipboardTrack!.artists[0] {
                                                self.targetTrack = tracks[0]
                                                self.state = .trackAvailable
                                                return
                                            }
                                        }
                                        self.state = .trackNotAvailable
                                    }
                                    
                                }
                            })
                        } else {
                            self.state = .trackNotAvailable
                        }
                    })
                }
            } else if url.host == "music.apple.com" {
                self.targetServiceType = .Spotify
                let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
                if url.pathComponents[2] == "album" {
                    if let id = components?.queryItems?.first(where: { $0.name == "i"})?.value {
                        print(id)
                        AppleMusicManager.shared.getIsrcID(id: id, completion: { track in
                            self.clipboardTrack = track
                            if track.isrcID != nil {
                                SpotifyManager.shared.getTracksFromIsrcID(isrcs: [track.isrcID!], completion: { tracks in
                                    if !tracks.isEmpty {
                                        if tracks[0].url != nil {
                                            self.targetTrack = tracks[0]
                                            self.state = .trackAvailable
                                        } else {
                                            self.state = .trackNotAvailable
                                        }
                                    } else {
                                        self.state = .trackNotAvailable
                                    }
                                })
                            } else {
                                self.state = .trackNotAvailable
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



struct ConvertTrackView: View {
    var track: Track
    
    var body: some View {
        VStack {
            if track.imageURL != nil {
                AsyncImage(url: track.imageURL!, placeholder: VStack {
                    Image(systemName: "ellipsis")
                    Text("Loading")
                    }, configuration: {
                        $0.resizable()
                    }).cornerRadius(5)
                    .frame(minWidth: 100, idealWidth: 300, maxWidth: 300, minHeight: 100, idealHeight: 300, maxHeight: 300, alignment: .center).padding(20)
                
            } else {
                VStack {
                    Image(systemName: "camera").frame(width: 300, height: 300, alignment: .center)
                    Text("Unable to find cover art")
                }
            }
            
            
        }
    }
}




