//
//  TrackListView.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI

struct TrackListView<ServiceManager: Manager>: View {
    @ObservedObject var playlist: Playlist
    var manager: ServiceManager
    
    var body: some View {
        VStack {
            if !playlist.tracks.isEmpty {
                Text("\(playlist.tracks.count) tracks").font(.subheadline)
            }
            List(playlist.tracks) { track in
                Text(track.name)
            }.navigationBarTitle(playlist.name)
                .navigationBarItems(trailing: NavigationLink(destination: TransferView(playlist: self.playlist, manager: self.manager), label: {
                    Text("Transfer")
                }))
                .onAppear {
                    self.manager.getPlaylistTracks(id: self.playlist.id, completion: { tracks in
                        self.playlist.tracks = tracks
                    })
            }
        }
    }
}

//struct TrackListView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackListView()
//    }
//}
