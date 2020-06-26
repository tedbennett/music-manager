//
//  SpotifyManager.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import Foundation
import OAuth2
import Alamofire

class SpotifyManager: Manager {
    static var type: ServiceType = .Spotify
    
    var baseURL = URL(string: "https://api.spotify.com/v1")!
    var searchURL = URL(string: "https://open.spotify.com/search")!

    var authClient = OAuth2CodeGrant(settings: [
        "client_id": "e164f018712e4c6ba906a595591ff010",
        "authorize_uri": "https://accounts.spotify.com/authorize",
        "token_uri": "https://accounts.spotify.com/api/token",
        "redirect_uris": ["music-manager://oauth-callback/"],
        "use_pkce": true,
        "scope": "playlist-read-private%20playlist-modify-private",
        "keychain": true,
        ] as OAuth2JSON)

    lazy var loader = OAuth2DataLoader(oauth2: authClient)
    
    static let shared = SpotifyManager()
    
    private init() {}
    
    func authorize(completion: @escaping (Bool) -> Void) {
        
        authClient.authorize(callback: {authParameters, error in
            if authParameters != nil {
                completion(true)
            }
            else {
                print("Authorization was canceled or went wrong: \(String(describing: error))")
                // error will not be nil
                if error?.description == "Refresh token revoked" {
                    self.authClient.forgetTokens()
                }
                completion(false)
            }
            
        })
        
    }
    
    func getUserPlaylists(completion: @escaping ([Playlist]) -> ()) {
        let url = baseURL.appendingPathComponent("me/playlists")
        
        let request = authClient.request(forURL: url)
        
        self.loader = OAuth2DataLoader(oauth2: authClient)
        loader.perform(request: request) { response in
            do {
                let dict = try response.responseJSON()
                var playlists = [Playlist]()
                DispatchQueue.main.async {
                    print(dict)
                    for case let result in dict["items"] as! [[String: Any]] {
                        if let playlist = try? Playlist(fromSpotify: result) {
                            playlists.append(playlist)
                            
                            
                        }
                    }
                    completion(playlists)
                    // you have received `dict` JSON data!
                }
            }
            catch let error {
                DispatchQueue.main.async {
                    print(error)
                    // an error occurred
                }
            }
        }
    }
    
    func getPlaylistTracks(id: String, completion: @escaping ([Track]) -> ()) {
        let url = baseURL.appendingPathComponent("playlists/\(id)/tracks")
        
        let request = authClient.request(forURL: url)
        
        self.loader = OAuth2DataLoader(oauth2: authClient)
        loader.perform(request: request) { response in
            do {
                let dict = try response.responseJSON()
                var tracks = [Track]()
                DispatchQueue.main.async {
                    print(dict)
                    for case let result in dict["items"] as! [[String: Any]] {
                        let local = result["is_local"] as! Bool
                        
                        let track = result["track"] as! [String:Any]
                        
                        if let track = try? Track(fromSpotify: track) {
                            track.local = local
                            tracks.append(track)
                        }
                    }
                    completion(tracks)
                    // you have received `dict` JSON data!
                }
            }
            catch let error {
                DispatchQueue.main.async {
                    print(error)
                    // an error occurred
                }
            }
        }
    }
    
    func getIsrcID(id: String, completion: @escaping (Track) -> ()) {
        let url = baseURL.appendingPathComponent("tracks/\(id)")
        
        let request = authClient.request(forURL: url)
        
        self.loader = OAuth2DataLoader(oauth2: authClient)
        loader.perform(request: request) { response in
            do {
                let dict = try response.responseJSON()
                DispatchQueue.main.async {
                    print(dict)
                    if let track = try? Track(fromSpotify: dict) {
                        completion(track)
                    }
                    // you have received `dict` JSON data!
                }
            }
            catch let error {
                DispatchQueue.main.async {
                    print(error)
                    // an error occurred
                }
            }
        }
    }
    
    func getTracksFromIsrcID(isrcs: [String], completion: @escaping (([Track]) -> ())) {
        var tracks = [Track]()
        
        for isrc in isrcs {
            let url = baseURL.appendingPathComponent("search")
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "q", value: "isrc:\(isrc)"), URLQueryItem(name: "type", value: "track"), URLQueryItem(name: "limit", value: "1")]
            
            let request = authClient.request(forURL: urlComponents.url!)
            
            self.loader = OAuth2DataLoader(oauth2: authClient)
            loader.perform(request: request) { response in
                do {
                    let dict = try response.responseJSON()
                    DispatchQueue.main.async {
                        print(dict)
                        let tracksJSON = dict["tracks"] as! [String: Any]
                        
                        if let items = tracksJSON["items"] as? [[String:Any]] {
                            if let track = try? Track(fromSpotify: items[0]) {
                                tracks.append(track)
                            }
                        }
                        completion(tracks)
                        // you have received `dict` JSON data!
                    }
                }
                catch let error {
                    DispatchQueue.main.async {
                        print(error)
                        // an error occurred
                    }
                }
            }
        }
    }
    
    func getSearchResults(for search: String, completion: @escaping ([Track]) -> ()) {
        
        let url = baseURL.appendingPathComponent("search")
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [URLQueryItem(name: "q", value: search), URLQueryItem(name: "type", value: "track"), URLQueryItem(name: "limit", value: "5")]
        if urlComponents.url == nil {
            return
        }
        let request = authClient.request(forURL: urlComponents.url!)
        
        
        self.loader = OAuth2DataLoader(oauth2: authClient)
        loader.perform(request: request) { response in
            do {
                let dict = try response.responseJSON()
                var tracks = [Track]()
                DispatchQueue.main.async {
                    print(dict)
                    let tracksJSON = dict["tracks"] as! [String: Any]
                    
                    let items = tracksJSON["items"] as! [[String:Any]]
                    for item in items {
                        if let track = try? Track(fromSpotify: item) {
                            tracks.append(track)
                        }
                    }
                    completion(tracks)
                }
            }
            catch let error {
                DispatchQueue.main.async {
                    print(error)
                    // an error occurred
                }
            }
        }
    }
    

    
    
}

extension Playlist {
    convenience init(fromSpotify json: [String: Any]) throws {
        guard let id = json["id"] as? String
            else { throw SerializationError.missing("id") }
        
        guard let name = json["name"] as? String
            else { throw SerializationError.missing("name") }
        
        guard let imagesJSON = json["images"] as? [[String:Any]]
            else { throw SerializationError.missing("images") }
        
        var imageURL: URL?
        for image in imagesJSON {
            if image["height"] as? Int == 640 {
                if let urlString = image["url"] as? String {
                    imageURL = URL(string: urlString)
                }
            }
        }
        
        if imageURL == nil {
            throw SerializationError.missing("imageURL")
        }
        self.init(id: id, name: name, imageURL: imageURL!)
    }
}

extension Track {
    convenience init(fromSpotify json: [String: Any]) throws {
        
        let id = json["id"] as? String
        
        guard let externalUrls = json["external_urls"] as? [String:Any]
            else { throw SerializationError.missing("external_urls") }
        var url: URL?
        if let urlString = externalUrls["spotify"] as? String {
            url = URL(string: urlString)
        }
        
        guard let name = json["name"] as? String
            else { throw SerializationError.missing("name") }
        
        guard let artistsJSON = json["artists"] as? [[String:Any]]
            else { throw SerializationError.missing("artists") }
        
        guard let albumJSON = json["album"] as? [String:Any],
            let albumName = albumJSON["name"] as? String,
            let imagesJSON = albumJSON["images"] as? [[String:Any]]
            else { throw SerializationError.missing("album") }
        
        
        var imageURL: URL?
        for image in imagesJSON {
            if image["height"] as? Int == 640 {
                if let imageUrlString = image["url"] as? String {
                    imageURL = URL(string: imageUrlString)
                }
            }
        }
        
        let externalIdsJSON = json["external_ids"] as? [String: Any]
        var isrcID: String?
        if externalIdsJSON != nil, !externalIdsJSON!.isEmpty {
            isrcID = externalIdsJSON!["isrc"] as? String
        }
        
        var artists = [String]()
        for artist in artistsJSON {
            if let artistName = artist["name"] as? String {
                artists.append(artistName)
            }
        }
        self.init(serviceId: id ?? UUID().uuidString, name: name, url: url, local: false, artists: artists, album: albumName, imageURL: imageURL, isrcID: isrcID)
    }
}



