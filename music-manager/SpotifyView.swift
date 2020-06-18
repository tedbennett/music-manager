//
//  SpotifyView.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI

struct SpotifyView: View {
    @State private var playlists = [Playlist]()
    
    var body: some View {
        NavigationView {
            List(playlists) { playlist in
                NavigationLink(destination: TrackListView(id: playlist.id, name: playlist.name)) {
                    Text(playlist.name)
                }
                
            }.navigationBarTitle("Playlists")
            .onAppear {
                SpotifyManager.shared.getUserPlaylists(completion: { playlists in
                    self.playlists = playlists
                })
            }
        }
        
    }
}
