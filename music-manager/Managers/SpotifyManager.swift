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
import PromiseKit

class SpotifyManager {
    static var type: ServiceType = .Spotify
    
    var baseURL = URL(string: "https://api.spotify.com/v1")!
    
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
    
    func fetchUserPlaylists() -> Promise<[Playlist]> {
        let (url, headers, parameters) = getUserPlaylistsUrl()
        return fetchUserPlaylists(url: url, headers: headers, parameters: parameters, playlists: [])
    }
    
    private func getUserPlaylistsUrl() -> (url: URL, headers: HTTPHeaders, parameters: Parameters) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(authClient.accessToken!)"
        ]
        let parameters: Parameters = [
            "limit": "50"
        ]
        let url = baseURL.appendingPathComponent("me/playlists")
        return (url: url, headers: headers, parameters: parameters)
    }
    
    private func fetchUserPlaylists(url: URL, headers: HTTPHeaders, parameters: Parameters, playlists: [Playlist]) -> Promise<[Playlist]> {
        return fetchPlaylistsFromPage(url: url, headers: headers, parameters: parameters)
            .then { (response: SpotifyPagingObject<SpotifyPlaylist>) -> Promise<[Playlist]> in
                var newPlaylists = playlists
                newPlaylists.append(contentsOf: response.items.map { Playlist(spotifyResponse: $0)})
                if response.next != nil {
                    return self.fetchUserPlaylists(url: response.next!, headers: headers, parameters: parameters, playlists: newPlaylists)
                } else {
                    return Promise { $0.fulfill(newPlaylists) }
                }
        }
    }
    
    private func fetchPlaylistsFromPage(url: URL, headers: HTTPHeaders, parameters: Parameters) -> Promise<SpotifyPagingObject<SpotifyPlaylist>> {
        return Promise { seal in
            AF.request(url, parameters: parameters, headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(SpotifyPagingObject<SpotifyPlaylist>.self, from: data!)
                                seal.fulfill(decoded)
                                
                            } catch {
                                seal.reject(error)
                        }
                        
                        case .failure(let error):
                            seal.reject(error)
                    }
            }
        }
    }
    
//    func fetchUserPlaylists() -> Promise<[Playlist]> {
//        return Promise { seal in
//            let headers: HTTPHeaders = [
//                "Authorization": "Bearer \(authClient.accessToken!)"
//            ]
//            let parameters = [
//                "limit": "50"
//            ]
//            AF.request(baseURL.appendingPathComponent("me/playlists"), parameters: parameters, headers: headers)
//                .validate()
//                .response { response in
//                    switch response.result {
//                        case .success(let data):
//                            do {
//                                let decoded = try JSONDecoder().decode(SpotifyPagingObject<SpotifyPlaylist>.self, from: data!)
//                                seal.fulfill(decoded.items.map { Playlist(spotifyResponse: $0 )})
//                            } catch {
//                                seal.reject(error)
//                        }
//
//                        case .failure(let error):
//                            seal.reject(error)
//                    }
//            }
//        }
//    }
    
    func fetchPlaylistTracks(id: String) -> Promise<[Track]> {
        let (url, headers) = getPlaylistTracksUrl(id: id)
        return fetchPlaylistTracks(url: url, headers: headers, tracks: [])
    }
    
    private func fetchPlaylistTracks(url: URL, headers: HTTPHeaders, tracks: [Track]) -> Promise<[Track]> {
        return fetchTracksFromPlaylistPage(url: url, headers: headers)
            .then { (response: SpotifyPagingObject<SpotifyPlaylistTrack>) -> Promise<[Track]> in
                var newTracks = tracks
                newTracks.append(contentsOf: response.items.map { Track(spotifyResponse: $0)})
                if response.next != nil {
                    return self.fetchPlaylistTracks(url: response.next!, headers: headers, tracks: newTracks)
                } else {
                    return Promise { $0.fulfill(newTracks) }
                }
        }
    }
    
    private func getPlaylistTracksUrl(id: String) -> (url: URL, headers: HTTPHeaders) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(authClient.accessToken!)"
        ]
        let url = baseURL.appendingPathComponent("playlists/\(id)/tracks")
        return (url: url, headers: headers)
    }
    
    private func fetchTracksFromPlaylistPage(url: URL, headers: HTTPHeaders) -> Promise<SpotifyPagingObject<SpotifyPlaylistTrack>> {
        return Promise { seal in
            AF.request(url, headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(SpotifyPagingObject<SpotifyPlaylistTrack>.self, from: data!)
                                seal.fulfill(decoded)
                            } catch {
                                seal.reject(error)
                        }
                        
                        case .failure(let error):
                            seal.reject(error)
                    }
            }
        }
    }
    
    
    
    
    //    func fetchPlaylistTracks(id: String) -> Promise<[Track]> {
    //        return Promise { seal in
    //            let headers: HTTPHeaders = [
    //                "Authorization": "Bearer \(authClient.accessToken!)"
    //            ]
    //            AF.request(baseURL.appendingPathComponent("playlists/\(id)/tracks"), headers: headers)
    //                .validate()
    //                .response { response in
    //                    switch response.result {
    //                        case .success(let data):
    //                            do {
    //                                let decoded = try JSONDecoder().decode(SpotifyPagingObject<SpotifyPlaylistTrack>.self, from: data!)
    //                                seal.fulfill(decoded.items.map { Track(spotifyResponse: $0)})
    //                            } catch {
    //                                seal.reject(error)
    //                        }
    //
    //                        case .failure(let error):
    //                            seal.reject(error)
    //                    }
    //            }
    //        }
    //    }
    
    func fetchIsrcId(id: String) -> Promise<Track> {
        return Promise { seal in
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(authClient.accessToken!)"
            ]
            AF.request(baseURL.appendingPathComponent("/tracks/\(id)"), headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(SpotifyTrack.self, from: data!)
                                seal.fulfill(Track(spotifyResponse: decoded, isLocal: false ))
                            } catch {
                                seal.reject(error)
                        }
                        
                        case .failure(let error):
                            seal.reject(error)
                    }
            }
        }
    }
    
    func fetchTrackFromIsrcId(isrc: String) -> Promise<[Track]>{
        return Promise { seal in
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(authClient.accessToken!)"
            ]
            let parameters = [
                "q": "isrc:\(isrc)",
                "type": "track",
                "limit": "1"
            ]
            AF.request(baseURL.appendingPathComponent("/search"), parameters: parameters, headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(SpotifySearch.self, from: data!)
                                seal.fulfill(decoded.tracks!.items.map { Track(spotifyResponse: $0, isLocal: false) })
                            } catch {
                                seal.reject(error)
                        }
                        
                        case .failure(let error):
                            seal.reject(error)
                    }
            }
        }
    }
    
    func fetchTrackSearchResults(for search: String) -> Promise<[Track]> {
        return Promise { seal in
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(authClient.accessToken!)"
            ]
            let parameters = [
                "q": search,
                "type": "track",
                "limit": "5"
            ]
            AF.request(baseURL.appendingPathComponent("/search"), parameters: parameters, headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(SpotifySearch.self, from: data!)
                                seal.fulfill(decoded.tracks!.items.map {
                                    Track(spotifyResponse: $0, isLocal: false)
                                })
                            } catch {
                                seal.reject(error)
                        }
                        
                        case .failure(let error):
                            seal.reject(error)
                    }
            }
        }
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


