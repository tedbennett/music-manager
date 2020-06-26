//
//  PlaylistsView.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI

struct PlaylistsView<ServiceManager: Manager>: View {
    @Environment(\.imageCache) var cache: ImageCache
    
    var manager: ServiceManager
    @State var playlists = [Playlist]()
    var serviceType: ServiceType
    
    var body: some View {
        NavigationView {
            List(self.playlists) { playlist in
                NavigationLink(destination: TrackListView<ServiceManager>(serviceType: self.serviceType, playlist: playlist, manager: self.manager)) {
                    HStack {
                        if playlist.imageURL != nil {
                            AsyncImage(url: playlist.imageURL!, cache: self.cache, placeholder: Image(systemName: "ellipsis"), configuration: {
                                $0.resizable()
                            }).frame(width: 75, height: 75).cornerRadius(4)
                        } else {
                            Image(systemName: "camera").frame(width: 75, height: 75)
                        }
                        Text(playlist.name).font(.headline).lineLimit(2)
                    }
                }
                
            }.navigationBarTitle("Playlists")
                .onAppear {
                    if self.playlists.isEmpty {
                        self.manager.getUserPlaylists(completion: { playlists in
                            self.playlists = playlists
                        })
                    }
            }
        }
    }
}

//struct PlaylistsView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistsView()
//    }
//}

