//
//  PlaylistsView.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI
import PromiseKit

struct PlaylistsView: View {
    @Environment(\.imageCache) var cache: ImageCache
    
    @State var playlists = [Playlist]()
    var service: ServiceType
    
    var body: some View {
        NavigationView {
            List(self.playlists) { playlist in
                NavigationLink(destination: TrackListView(service: self.service, playlist: playlist)) {
                    HStack {
                        
                        if playlist.imageURL != nil {
                            ImageView(url: playlist.imageURL!)
//                            AsyncImage(url: playlist.imageURL!, cache: self.cache, placeholder: Image(systemName: "ellipsis"), configuration: {
//                                $0.resizable()
//                            }).frame(width: 75, height: 75).cornerRadius(4)
                        } else {
                            Image(systemName: "camera").frame(width: 75, height: 75)
                        }
                        VStack {
                        Text(playlist.name).font(.headline).lineLimit(2)
                        Text(playlist.id).font(.subheadline)
                        }
                    }
                }
                
            }.navigationBarTitle("Playlists")
                .navigationBarItems(trailing: Image(uiImage: UIImage(systemName:"camera")!))
                .onAppear {
                    if self.playlists.isEmpty {
                        if self.service == .AppleMusic {
                            firstly {
                                AppleMusicManager.shared.fetchLibraryPlaylists()
                            }
                            .done { playlists in
                                self.playlists = playlists
                            }
                            .catch { error in
                                print(error)
                            }
                        } else {
                            firstly {
                                SpotifyManager.shared.fetchUserPlaylists()
                            }
                            .done { playlists in
                                self.playlists = playlists
                            }
                            .catch { error in
                                print(error)
                            }
                        }
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
