//
//  SearchView.swift
//  music-manager
//
//  Created by Ted Bennett on 25/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI
import PromiseKit

struct SearchView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var searchTerm: String = ""
    @State private var results = [Track]()
    var service: ServiceType
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter search terms...", text: $searchTerm, onCommit: {
                    self.getSearchResults()
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
                    self.getSearchResults()
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
    
    func getSearchResults() {
        if self.service == .Spotify {
            firstly {
                SpotifyManager.shared.fetchTrackSearchResults(for: self.searchTerm)
            }
            .done { tracks in
                self.results = tracks
            }
            .catch { error in
                print(error)
            }
        } else {
            firstly {
                AppleMusicManager.shared.fetchTrackSearchResults(for: self.searchTerm)
            }
            .done { tracks in
                self.results = tracks
            }
            .catch { error in
                print(error)
            }
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView(service: .Spotify)
    }
}
