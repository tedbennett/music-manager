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
                let playlistsResponse = try JSONDecoder().decode(SpotifyPagingObject<SpotifyPlaylist>.self, from: response.data!)
                DispatchQueue.main.async {
                    
                    let playlists : [Playlist] = playlistsResponse.items.map {
                        Playlist(spotifyResponse: $0)
                    }
                    
                    completion(playlists)
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
                let tracksResponse = try JSONDecoder().decode(SpotifyPagingObject<SpotifyPlaylistTrack>.self, from: response.data!)
                DispatchQueue.main.async {
                    
                    let tracks : [Track] = tracksResponse.items.map {
                        Track(spotifyResponse: $0)
                    }
                    completion(tracks)
                }
            }
            catch let error {
                DispatchQueue.main.async {
                    print(error)
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
                let trackResponse = try JSONDecoder().decode(SpotifyTrack.self, from: response.data!)
                DispatchQueue.main.async {
                    completion(Track(spotifyResponse: trackResponse, isLocal: false))
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
        for isrc in isrcs {
            let url = baseURL.appendingPathComponent("search")
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
            urlComponents.queryItems = [URLQueryItem(name: "q", value: "isrc:\(isrc)"), URLQueryItem(name: "type", value: "track"), URLQueryItem(name: "limit", value: "1")]
            
            let request = authClient.request(forURL: urlComponents.url!)
            
            self.loader = OAuth2DataLoader(oauth2: authClient)
            loader.perform(request: request) { response in
                do {
                    let json = try response.responseJSON()
                    let searchResponse = try JSONDecoder().decode(SpotifySearch.self, from: response.data!)
                    DispatchQueue.main.async {
                        
                        let tracks : [Track] = searchResponse.tracks!.items.map {
                            Track(spotifyResponse: $0, isLocal: false)
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
                let searchResponse = try JSONDecoder().decode(SpotifySearch.self, from: response.data!)
                DispatchQueue.main.async {
                    
                    let tracks : [Track] = searchResponse.tracks!.items.map {
                        Track(spotifyResponse: $0, isLocal: false)
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
    convenience init(spotifyResponse response: SpotifyPlaylist) {
        let id = response.id
        let name = response.name
        let description = response.description ?? ""
        let imageURL = response.images.first?.url
        
        self.init(id: id, name: name, description: description, imageURL: imageURL!)
    }
}

extension Track {
    convenience init(spotifyResponse response: SpotifyPlaylistTrack) {
        let isLocal = response.isLocal
        self.init(spotifyResponse: response.track, isLocal: isLocal)
    }
    
    
    convenience init(spotifyResponse response: SpotifyTrack, isLocal: Bool) {
        let id = response.id ?? UUID().uuidString
        let name = response.name
        let url = response.externalUrls.spotify
        let imageURL = response.album.images.first?.url
        let artists = response.artists.map { $0.name }
        let albumName = response.album.name
        let isrcID = response.externalIds?.isrc
        
        self.init(serviceId: id, name: name, url: url, local: isLocal, artists: artists, album: albumName, imageURL: imageURL, isrcID: isrcID)
    }
}


