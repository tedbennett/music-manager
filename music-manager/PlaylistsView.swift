//
//  PlaylistsView.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI

struct PlaylistsView<ServiceManager: Manager>: View {
    var manager: ServiceManager
    @State var playlists = [Playlist]()
    
    var body: some View {
        NavigationView {
            List(self.playlists) { playlist in
                NavigationLink(destination: TrackListView<ServiceManager>(playlist: playlist, manager: self.manager)) {
                    Text(playlist.name).font(.headline)
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

