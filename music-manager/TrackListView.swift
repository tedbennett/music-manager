//
//  TrackListView.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI

struct TrackListView<ServiceManager: Manager>: View {
    @SwiftUI.Environment(\.imageCache) var cache: ImageCache
    
    @ObservedObject var playlist: Playlist
    var manager: ServiceManager
    @State private var imagesFinishedLoading = false
    
    var body: some View {
        VStack {
            if !playlist.tracks.isEmpty {
                Text("\(playlist.tracks.count) tracks").font(.subheadline)
            }
            List(playlist.tracks) { track in
                HStack {
                    if track.imageURL != nil {
                        AsyncImage(url: track.imageURL!, cache: self.cache, placeholder: Image(systemName: "ellipsis"), configuration: { $0.resizable() }).frame(width: 75, height: 75)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(track.name)
                        Text(track.artists[0]).font(.subheadline)
                    }
                }
                
            }.navigationBarTitle(playlist.name)
                .navigationBarItems(trailing: NavigationLink(destination: TransferView(playlist: self.playlist, manager: self.manager), label: {
                    Text("Transfer")
                }))
                .onAppear {
                    if self.playlist.tracks.isEmpty {
                        self.manager.getPlaylistTracks(id: self.playlist.id, completion: { tracks in
                            self.playlist.tracks = tracks
                        })
                        
                    }
            }
        }
    }
}

//struct TrackListView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackListView()
//    }
//}
