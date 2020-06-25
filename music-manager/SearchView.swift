//
//  SearchView.swift
//  music-manager
//
//  Created by Ted Bennett on 25/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI

struct SearchView<ServiceManager: Manager>: View {
    @Environment(\.presentationMode) var presentationMode
    @State var searchTerm: String = ""
    @State private var results = [Track]()
    var manager: ServiceManager
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter search terms...", text: $searchTerm, onCommit: {
                    self.manager.getSearchResults(for: self.searchTerm) { tracks in
                        self.results = tracks
                    }
                }).textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                List(self.results) { track in
                    
                    TrackView(track: track).gesture(
                        TapGesture()
                            .onEnded { _ in
                                if track.url != nil {
                                UIApplication.shared.open(track.url!)
                                }
                        }
                    )
                }
            }.onAppear {
                if self.searchTerm != "" {
                    self.manager.getSearchResults(for: self.searchTerm) { tracks in
                        self.results = tracks
                    }
                }
            }
            .navigationBarTitle("Search")
                .navigationBarItems(trailing: Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Dismiss")
                })
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(manager: SpotifyManager.shared)
    }
}
