//
//  MusicTypes.swift
//  music-manager
//
//  Created by Ted Bennett on 23/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import Foundation

protocol Manager {
    func getUserPlaylists(completion: @escaping ([Playlist]) -> ())
    func getPlaylistTracks(id: String, completion: @escaping ([Track]) -> ())
    func getIsrcID(id: String, completion: @escaping (Track) -> ())
    func getTracksFromIsrcID(isrcs: [String], completion: @escaping ([Track]) -> ())
}


class Playlist: ObservableObject, Identifiable {
    var id: String
    var name: String
    var imageURL: String?
    var url: String?
    @Published var tracks: [Track]
    
    init(id: String, name: String, url: String? = nil, imageURL: String? = nil,
         tracks: [Track] = []) {
        self.id = id
        self.name = name
        self.url = url
        self.imageURL = imageURL
        self.tracks = tracks
    }
}

class Track: ObservableObject, Identifiable {
    var id: String
    var name: String
    var local: Bool
    var artists: [Artist]
    var album: Album
    var isrcID: String?
    var url: String?
    
    init(id: String, name: String, url: String? = nil, local: Bool, artists: [Artist], album: Album, isrcID: String? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.local = local
        self.artists = artists
        self.album = album
        self.isrcID = isrcID
    }
}


struct Artist: Hashable {
    var name: String
}

struct Album {
    var name: String
    var imageURL: String?
}

enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any)
}
