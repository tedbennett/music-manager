//
//  TrackListView.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI

struct TrackListView: View {
    @State var tracks = [Track]()
    
    var id: String
    var name: String
    var body: some View {
        List(tracks) { track in
            Text(track.name)
        }.onAppear {
            SpotifyManager.shared.getPlaylistTracks(id: self.id, completion: { tracks in
                self.tracks = tracks
            })
        }.navigationBarTitle(name)
        
    }
}

//struct TrackListView_Previews: PreviewProvider {
//    static var previews: some View {
//        TrackListView()
//    }
//}
