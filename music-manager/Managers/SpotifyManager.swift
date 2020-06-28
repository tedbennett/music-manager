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
    var userId: String? = KeychainWrapper.standard.string(forKey: "spotifyUserId")
    
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
        self.authClient.forgetTokens()
        authClient.authorize(callback: {authParameters, error in
            if authParameters != nil {
                self.fetchUserId()
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
    
    private func fetchUserId() {
        let url = baseURL.appendingPathExtension("/me")
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(authClient.accessToken!)"
        ]
        AF.request(url, headers: headers)
            .validate()
            .response { response in
                switch response.result {
                    case .success(let data):
                        do {
                            let decoded = try JSONDecoder().decode(SpotifyUserPrivate.self, from: data!)
                            self.userId = decoded.id
                        } catch {
                            print(error)
                    }
                    
                    case .failure(let error):
                        print(error)
                }
        }
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
        return fetchPaginatedData(url: url, headers: headers, parameters: parameters)
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
    
    func fetchPlaylistTracks(id: String) -> Promise<[Track]> {
        let (url, headers) = getPlaylistTracksUrl(id: id)
        return fetchPlaylistTracks(url: url, headers: headers, tracks: [])
    }
    
    private func getPlaylistTracksUrl(id: String) -> (url: URL, headers: HTTPHeaders) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(authClient.accessToken!)"
        ]
        let url = baseURL.appendingPathComponent("playlists/\(id)/tracks")
        return (url: url, headers: headers)
    }
    
    private func fetchPlaylistTracks(url: URL, headers: HTTPHeaders, tracks: [Track]) -> Promise<[Track]> {
        return fetchPaginatedData(url: url, headers: headers)
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
    
    private func fetchPaginatedData<SpotifyObject>(url: URL, headers: HTTPHeaders, parameters: Parameters = [:]) -> Promise<SpotifyPagingObject<SpotifyObject>> {
        return Promise { seal in
            AF.request(url, parameters: parameters, headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(SpotifyPagingObject<SpotifyObject>.self, from: data!)
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
    
    func fetchTracksFromIsrcIds(isrcIds: [String]) -> Promise<[Track]> {
        return Promise { $0.fulfill(isrcIds) }.thenMap { (id: String) in
            self.fetchTrackFromIsrcId(isrc: id)
        }.then { (tracks: [[Track]]) -> Promise<[Track]> in
            var result = [Track]()
            for track in tracks {
                result.append(contentsOf: track)
            }
            return Promise { $0.fulfill(result)}
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
    
//    func createLibraryPlaylist(name: String, ids: [String]) {
//        let (url, headers, body) = createLibraryPlaylistUrl(name: name)
//        when(fulfilled: createLibraryPlaylist(url: url, headers: headers, body: body), fetchTracksFromIsrcIds(isrcIds: ids))
//            .then { (playlistId: String, tracks: [Track]) -> Promise<Void> in
//                self.addTracksToLibraryPlaylist(id: playlistId, trackIds: tracks.map { $0.serviceId })
//        }
//        .catch { error in
//            print(error)
//        }
//    }
//
//    private func createLibraryPlaylistUrl() {
//        if userId == nil {
//            fetchUserId
//        }
//    }
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


