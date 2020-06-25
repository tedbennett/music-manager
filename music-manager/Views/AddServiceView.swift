//
//  AddServiceView.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI
import OAuth2

struct AddServiceView: View {
    @Binding var spotifyConnected: Bool
    @Binding var appleMusicConnected: Bool
    @State var failedToConnect = false
    var body: some View {
        VStack {
            if !spotifyConnected {
                Spacer()
                Button(action: {
                    SpotifyManager.shared.authorize(completion: { authorised in
                        self.spotifyConnected = authorised
                    })
                }) {
                    Text("Log In to Spotify")
                }
            }
            if !appleMusicConnected {
                Spacer()
                Button(action: {
                    AppleMusicManager.shared.getAppleMusicAuth() { userToken, _ in
                        if userToken != nil {
                            self.appleMusicConnected = true
                        } else {
                            self.failedToConnect = true
                        }
                    }
                    
                }) {
                    Text("Log In to Apple Music")
                }.alert(isPresented: self.$failedToConnect) {
                Alert(title: Text("Unknown Error"), message: Text("Failed to connect to Apple Music"), dismissButton: .default(Text("OK")))
                }
            }
            Spacer()
        }
    }
}
