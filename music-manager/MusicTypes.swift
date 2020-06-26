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
    func getTracksFromIsrcID(isrcs: [String], completion: @escaping ([Track]) -> ())
    func getSearchResults(for search: String, completion: @escaping ([Track]) -> ())
    static var type: ServiceType {get}
}

enum ServiceType {
    case AppleMusic
    case Spotify
}

let serviceNames: [ServiceType:String] = [
    .AppleMusic: "Apple Music",
    .Spotify: "Spotify"
]



class Playlist: ObservableObject, Identifiable {
    var id: String
    var name: String
    var imageURL: URL?
    var url: URL?
    var description: String
    @Published var tracks: [Track]
    
    init(id: String, name: String, description: String, url: URL? = nil, imageURL: URL? = nil,
         tracks: [Track] = []) {
        self.id = id
        self.name = name
        self.url = url
        self.imageURL = imageURL
        self.tracks = tracks
        self.description = description
    }
}

class Track: ObservableObject, Identifiable {
    var serviceId: String
    var name: String
    var local: Bool
    var artists: [String]
    var album: String
    var imageURL: URL?
    var isrcID: String?
    var url: URL?
    @Published var image: UIImage?
    
    init(serviceId: String, name: String, url: URL? = nil, local: Bool, artists: [String], album: String, imageURL: URL?, isrcID: String? = nil) {
        self.serviceId = serviceId
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
