//
//  AppleMusicView.swift
//  music-manager
//
//  Created by Ted Bennett on 19/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI

struct AppleMusicView: View {
    @State private var playlists = [Playlist]()
    var manager = AppleMusicManager.shared
    
    var body: some View {
        NavigationView {
            List(playlists) { playlist in
                NavigationLink(destination: TrackListView(id: playlist.id, name: playlist.name)) {
                    VStack(alignment: .leading){
                        Text(playlist.name).font(.headline)
                            //Text("\(playlist.trackCount) songs").font(.subheadline)
                    }
                }
                
            }.navigationBarTitle("Playlists")
                .onAppear {
                    self.manager.getUserPlaylists(completion: { playlists in
                        self.playlists = playlists
                    })
            }
        }
        
    }
}

struct AppleMusicView_Previews: PreviewProvider {
    static var previews: some View {
        AppleMusicView()
    }
}
