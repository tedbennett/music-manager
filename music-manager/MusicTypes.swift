//
//  MusicTypes.swift
//  music-manager
//
//  Created by Ted Bennett on 23/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import Foundation
import UIKit

protocol Manager {
    func getUserPlaylists(completion: @escaping ([Playlist]) -> ())
    func getPlaylistTracks(id: String, completion: @escaping ([Track]) -> ())
    func getIsrcID(id: String, completion: @escaping (Track) -> ())
    func getTracksFromIsrcID(isrcs: [String], completion: @escaping ([Track?]) -> ())
}


class Playlist: ObservableObject, Identifiable {
    var id: String
    var name: String
    var imageURL: URL?
    var url: URL?
    @Published var tracks: [Track]
    
    init(id: String, name: String, url: URL? = nil, imageURL: URL? = nil,
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
    var artists: [String]
    var album: String
    var imageURL: URL?
    var isrcID: String?
    var url: URL?
    @Published var image: UIImage?
    
    init(id: String, name: String, url: URL? = nil, local: Bool, artists: [String], album: String, imageURL: URL?, isrcID: String? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.local = local
        self.artists = artists
        self.album = album
        self.imageURL = imageURL
        self.isrcID = isrcID
    }
}

enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any)
}
