//
//  TrackListView.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI
import PromiseKit

struct TrackListView: View {
    var service: ServiceType
    @ObservedObject var playlist: Playlist
    @State private var imagesFinishedLoading = false
    @State private var finishedTransfer = false
    
    var body: some View {
        VStack {
            List(playlist.tracks) { track in
                TrackView(track: track)
            }.navigationBarTitle(playlist.name)
                .navigationBarItems(trailing:
                    //NavigationLink(destination: TransferView(playlist: self.playlist, manager: self.manager), label: {
                    Button(action: {
                        self.transferPlaylist()
                    }, label: {
                    Text("Transfer")
                        }).disabled(finishedTransfer)
            )
                .alert(isPresented: self.$finishedTransfer, content: {
                    Alert(title: Text("Transfer Success"))
                })
                .onAppear {
                    if self.playlist.tracks.isEmpty {
                        if self.service == .AppleMusic {
                            firstly {
                                AppleMusicManager.shared.fetchCatalogIdsFromPlaylist(id: self.playlist.id)
                            }
                            .then { ids in
                                AppleMusicManager.shared.fetchCatalogTracksFromIds(ids: ids)
                            }
                            .done { tracks in
                                self.playlist.tracks = tracks
                            }
                            .catch { error in
                                print(error)
                            }
                        } else {
                            firstly {
                                SpotifyManager.shared.fetchPlaylistTracks(id: self.playlist.id)
                            }
                            .done { tracks in
                                self.playlist.tracks = tracks
                            }
                            .catch { error in
                                print(error)
                            }
                        }
                        
                    }
            }
        }
    }
    func transferPlaylist() {
        if self.service == .Spotify {
            AppleMusicManager.shared.transferPlaylistToAppleMusic(name: self.playlist.name, with: self.playlist.tracks, completion: {
                self.finishedTransfer = true
            })
        }
    }
}






//struct TrackListView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackListView()
//    }
//}

struct TrackView: View {
    @Environment(\.imageCache) var cache: ImageCache
    @ObservedObject var track: Track
    var body: some View {
        HStack {
            if track.imageURL != nil {
                ImageView(url: track.imageURL!)
            } else {
                Image(systemName: "camera").frame(width: 75, height: 75)
            }
            
            VStack(alignment: .leading) {
                Text(track.name).bold().lineLimit(2).padding(.bottom, 5).foregroundColor(track.local ? .gray : Color(UIColor.label))
                Text(track.artists[0]).font(.subheadline).foregroundColor(track.local ? .gray : Color(UIColor.label))
            }
        }
    }
}
