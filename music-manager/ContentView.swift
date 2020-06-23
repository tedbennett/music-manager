//
//  ContentView.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var spotifyConnected = SpotifyManager.shared.authToken != nil
    @State var appleMusicConnected = AppleMusicManager.shared.userToken != nil
    var body: some View {
        TabView {
            ConvertView().tabItem {
                Text("Convert")
                Image(systemName: "arrow.right.arrow.left")
            }
            if spotifyConnected {
                PlaylistsView<SpotifyManager>(manager: SpotifyManager.shared).tabItem {
                    Text("Spotify")
                    Image(uiImage: UIImage(named: "spotify")!)
                }
            }
            if appleMusicConnected {
                PlaylistsView<AppleMusicManager>(manager: AppleMusicManager.shared).tabItem {
                    Text("Apple")
                    Image(uiImage: UIImage(named: "apple")!)
                }
            }
            if !spotifyConnected || !appleMusicConnected {
                AddServiceView(spotifyConnected: $spotifyConnected, appleMusicConnected: $appleMusicConnected).tabItem {
                    Text("Add Service")
                    Image(systemName: "plus")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
