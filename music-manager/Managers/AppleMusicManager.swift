//
//  AppleMusicManager.swift
//  music-manager
//
//  Created by Ted Bennett on 19/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import Foundation
import StoreKit
import Alamofire
import PromiseKit

class AppleMusicManager {
    static var type: ServiceType = .AppleMusic
    
    var baseURL = URL(string: "https://api.music.apple.com/v1/")!
    var developerToken = AppleMusicEnvironment.musicToken
    var userToken: String? = KeychainWrapper.standard.string(forKey: "appleMusicUserToken")
    var storefront: String? = KeychainWrapper.standard.string(forKey: "appleMusicStorefront")
    
    var controller = SKCloudServiceController()
    
    static let shared = AppleMusicManager()
    
    private init() {}
    
    func getNextURL(_ path: URL) -> URL {
        return URL(string: "https://api.music.apple.com" + path.absoluteString)!
    }
    
    func getAppleMusicAuth(completion: @escaping (String?, Error?) -> Void) {
        SKCloudServiceController.requestAuthorization { status in
            if status == .authorized {
                self.controller.requestCapabilities { capabilities, error in
                    if capabilities.contains(.addToCloudMusicLibrary) {
                        self.controller.requestUserToken(forDeveloperToken: self.developerToken) { userToken, error in
                            self.userToken = userToken
                            completion(userToken, error)
                            if userToken != nil {
                                KeychainWrapper.standard.set(userToken!, forKey: "appleMusicUserToken")
                                self.getUserStorefront()
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getUserStorefront() {
        let url = baseURL.appendingPathComponent("me/storefront")
        var request = URLRequest(url: url)
        request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
        request.setValue(userToken!, forHTTPHeaderField: "Music-User-Token")
        
        
        URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
            
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                for case let data in json["data"] as! [[String: Any]] {
                    let storefront = data["id"] as! String
                    self.storefront = storefront
                    KeychainWrapper.standard.set(storefront, forKey: "appleMusicStorefront")
                }
            }
        }.resume()
        
    }
    
    func fetchLibraryPlaylists() -> Promise<[Playlist]> {
        let (url, headers) = getLibraryPlaylistsUrl()
        return fetchLibraryPlaylists(url: url, headers: headers, playlists: [])
    }
    
    private func getLibraryPlaylistsUrl() -> (url: URL, headers: HTTPHeaders) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(developerToken)",
            "Music-User-Token": userToken!
        ]
        let url = baseURL.appendingPathComponent("me/library/playlists")
        return (url: url, headers: headers)
    }
    
    private func fetchLibraryPlaylists(url: URL, headers: HTTPHeaders, playlists: [Playlist]) -> Promise<[Playlist]> {
        return fetchPaginatedData(url: url, headers: headers)
            .then { (response: AppleMusicResponse<AppleMusicLibraryPlaylist>) -> Promise<[Playlist]> in
                var newPlaylists = playlists
                newPlaylists.append(contentsOf: response.data.map { Playlist(fromAppleMusicLibrary: $0)})
                if response.next != nil {
                    return self.fetchLibraryPlaylists(url: self.getNextURL(response.next!), headers: headers, playlists: newPlaylists)
                } else {
                    return Promise { $0.fulfill(newPlaylists) }
                }
        }
    }
    
    func fetchCatalogIdsFromPlaylist(id: String) -> Promise<[String]> {
        let (url, headers) = getCatalogIdsFromPlaylistUrl(id: id)
        return fetchCatalogIdsFromPlaylist(url: url, headers: headers, ids: [])
    }
    
    private func getCatalogIdsFromPlaylistUrl(id: String) -> (url: URL, headers: HTTPHeaders) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(developerToken)",
            "Music-User-Token": userToken!
        ]
        let url = baseURL.appendingPathComponent("me/library/playlists/\(id)/tracks")
        return (url: url, headers: headers)
    }
    
    private func fetchCatalogIdsFromPlaylist(url: URL, headers: HTTPHeaders, ids: [String]) -> Promise<[String]> {
        return fetchPaginatedData(url: url, headers: headers)
            .then { (response: AppleMusicResponse<AppleMusicLibrarySong>) -> Promise<[String]> in
                var newIds = ids
                newIds.append(contentsOf: response.data.filter {
                    $0.attributes?.playParams?.catalogId != nil
                }
                .map { ($0.attributes?.playParams?.catalogId)! })
                if response.next != nil {
                    return self.fetchCatalogIdsFromPlaylist(url: self.getNextURL(response.next!), headers: headers, ids: newIds)
                } else {
                    return Promise { $0.fulfill(newIds) }
                }
        }
    }
    
    private func fetchPaginatedData<AppleMusicObject>(url: URL, headers: HTTPHeaders, parameters: Parameters = [:]) -> Promise<AppleMusicResponse<AppleMusicObject>> {
        return Promise { seal in
            AF.request(url, parameters: parameters, headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(AppleMusicResponse<AppleMusicObject>.self, from: data!)
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
    
    func fetchCatalogTracksFromIds(ids: [String]) -> Promise<[Track]> {
        let (url, headers, parameters) = getCatalogTracksFromIdsUrl(ids: ids)
        return fetchCatalogTracksFromIds(url: url, headers: headers, parameters: parameters, tracks: [])
    }
    
    private func getCatalogTracksFromIdsUrl(ids: [String]) -> (url: URL, headers: HTTPHeaders, parameters: Parameters) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(developerToken)",
            "Music-User-Token": userToken!
        ]
        let parameters = [
            "ids": ids.joined(separator: ","),
            "include": "artists"
        ]
        let url = baseURL.appendingPathComponent("catalog/\(storefront!)/songs")
        return (url: url, headers: headers, parameters: parameters)
    }
    
    private func fetchCatalogTracksFromIds(url: URL, headers: HTTPHeaders, parameters: Parameters, tracks: [Track]) -> Promise<[Track]> {
        return fetchPaginatedData(url: url, headers: headers, parameters: parameters)
            .then { (response: AppleMusicResponse<AppleMusicSong>) -> Promise<[Track]> in
                var newTracks = tracks
                newTracks.append(contentsOf: response.data.map { Track(fromAppleMusic: $0) })
                if response.next != nil {
                    return self.fetchCatalogTracksFromIds(url: self.getNextURL(response.next!), headers: headers, parameters: parameters, tracks: newTracks)
                } else {
                    return Promise { $0.fulfill(newTracks) }
                }
        }
    }
    
    
    func fetchIsrcId(id: String) -> Promise<Track> {
        return Promise { seal in
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(developerToken)",
                "Music-User-Token": userToken!
            ]
            AF.request(baseURL.appendingPathComponent("catalog/\(storefront!)/songs/\(id)"), headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                
                                let decoded = try JSONDecoder().decode(AppleMusicResponse<AppleMusicSong>.self, from: data!)
                                seal.fulfill(Track(fromAppleMusic: decoded.data[0]))
                            } catch {
                                seal.reject(error)
                        }
                        
                        case .failure(let error):
                            seal.reject(error)
                    }
            }
        }
    }
    
    func fetchLibraryPlaylistFromId(id: String) -> Promise<Playlist> {
        return Promise { seal in
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(developerToken)",
                "Music-User-Token": userToken!
            ]
            AF.request(baseURL.appendingPathComponent("me/library/playlists/\(id)"), headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                
                                let decoded = try JSONDecoder().decode(AppleMusicResponse<AppleMusicLibraryPlaylist>.self, from: data!)
                                seal.fulfill(Playlist(fromAppleMusicLibrary: decoded.data[0]))
                            } catch {
                                seal.reject(error)
                        }
                        
                        case .failure(let error):
                            seal.reject(error)
                    }
            }
        }
    }
    
    func fetchTrackFromIsrcId(isrcId: String) -> Promise<Track?> {
        return Promise { seal in
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(developerToken)",
                "Music-User-Token": userToken!
            ]
            let url = baseURL.appendingPathComponent("catalog/\(storefront ?? "us")/songs")
            let parameters: Parameters = ["filter[isrc]": isrcId]
            AF.request(url, parameters: parameters, headers: headers)
                .validate()
                .response { response in
                    let json = try? JSONSerialization.jsonObject(with: response.data!, options: []) as? [String: Any]
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(AppleMusicResponse<AppleMusicSong>.self, from: data!)
                                seal.fulfill(decoded.data.isEmpty ? nil : Track(fromAppleMusic: decoded.data[0]))
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
            self.fetchTrackFromIsrcId(isrcId: id)
        }.then { (tracks: [Track?]) -> Promise<[Track]> in
            
            return Promise { $0.fulfill(tracks.filter { $0 != nil }.map { $0! })}
        }
    }

    
    func fetchTrackSearchResults(for search: String) -> Promise<[Track]> {
        return Promise { seal in
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(developerToken)",
                "Music-User-Token": userToken!
            ]
            
            let escapedString = search.replacingOccurrences(of: " ", with: "+")
            let parameters = [
                "term": escapedString,
                "types": "songs",
                "limit": "5",
                "include": "artists"
            ]
            
            AF.request(baseURL.appendingPathComponent("catalog/\(storefront ?? "us")/search"), parameters: parameters, headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(AppleMusicSearchResponse.self, from: data!)
                                seal.fulfill((decoded.results.songs?.data.map { Track(fromAppleMusic: $0) })!)
                            } catch {
                                seal.reject(error)
                        }
                        
                        case .failure(let error):
                            seal.reject(error)
                    }
            }
        }
    }
    
    
    
    func getTracksFromIsrcID(isrcs: [String], completion: @escaping ([Track]) -> ()) {
        guard var url = URLComponents(string: baseURL.absoluteString + "catalog/\(storefront ?? "us")/songs") else { return }
        
        url.queryItems = [URLQueryItem(name: "filter[isrc]", value: isrcs.joined(separator: ","))]
        
        var request = URLRequest(url: url.url!)
        request.setValue("Bearer " + developerToken, forHTTPHeaderField: "Authorization")
        //request.setValue(userToken!, forHTTPHeaderField: "Music-User-Token")
        var tracks = [Track]()
        URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                for case let data in json["data"] as! [[String: Any]] {
                    if let track = try? Track(fromAppleMusic: data) {
                        tracks.append(track)
                    }
                }
                
            }
            DispatchQueue.main.async {
                
                completion(tracks)
                
            }
        }.resume()
        
    }
    
    
    
    func createLibraryPlaylist(name: String, ids: [String]) {
        let (url, headers, body) = createLibraryPlaylistUrl(name: name)
        when(fulfilled: createLibraryPlaylist(url: url, headers: headers, body: body), fetchTracksFromIsrcIds(isrcIds: ids))
            .then { (playlistId: String, tracks: [Track]) -> Promise<Void> in
                self.addTracksToLibraryPlaylist(id: playlistId, trackIds: tracks.map { $0.serviceId })
        }
        .catch { error in
            print(error)
        }
    }
    
    private func createLibraryPlaylistUrl(name: String) -> (url: URL, headers: HTTPHeaders, body: [String:Any]) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(developerToken)",
            "Music-User-Token": userToken!,
            "Content-type": "application/json"
        ]
        let body = [
            "attributes": [
                "name": name
            ]
            ] as [String : Any]
        let url = baseURL.appendingPathComponent("me/library/playlists")
        return (url: url, headers: headers, body: body)
    }
    
    private func createLibraryPlaylist(url: URL, headers: HTTPHeaders, body: [String: Any]) -> Promise<String> {
        return Promise { seal in
            AF.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(AppleMusicResponse<AppleMusicLibraryPlaylist>.self, from: data!)
                                print(decoded.data[0])
                                seal.fulfill(decoded.data[0].id)
                            } catch {
                                seal.reject(error)
                        }
                        
                        case .failure(let error):
                            seal.reject(error)
                    }
            }
        }
    }
    
    private func addTracksToLibraryPlaylist(id: String, trackIds: [String]) -> Promise<Void> {
        let (url, headers) = addTracksToLibraryPlaylistUrl(id: id)
        
        var songObjects = [[String:String]]()
        for id in trackIds {
            songObjects.append( ["id": id, "type": "songs"])
        }
        return addTracksToLibraryPlaylist(url: url, headers: headers, tracks: songObjects)
    }
    
    private func addTracksToLibraryPlaylistUrl(id: String) -> (url: URL, headers: HTTPHeaders) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(developerToken)",
            "Music-User-Token": userToken!
        ]
        let url = baseURL.appendingPathComponent("me/library/playlists/\(id)/tracks")
        return (url: url, headers: headers)
    }
    
    private func addTracksToLibraryPlaylist(url: URL, headers: HTTPHeaders, tracks: [[String:String]]) -> Promise<Void> {
        let body = [
            "data": Array(tracks[0...min(24, tracks.count - 1)])
            ] as [String : Any]
        return addTracksToLibraryPlaylist(url: url, headers: headers, body: body)
            .then { () -> Promise<Void> in
                if tracks.count > 25 {
                    return self.addTracksToLibraryPlaylist(url: url, headers: headers, tracks: Array(tracks[25...]))
                } else {
                    return Promise { $0.fulfill(()) }
                }
        }
    }
    
    private func addTracksToLibraryPlaylist(url: URL, headers: HTTPHeaders, body: [String: Any]) -> Promise<Void> {
        return Promise { seal in
            AF.request(url, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(_):
                            seal.fulfill(())
                        case .failure(let error):
                            seal.reject(error)
                    }
            }
        }
    }
    
}



extension Playlist {
    convenience init(fromAppleMusic json: [String: Any]) throws {
        guard let id = json["id"] as? String
            else { throw SerializationError.missing("id") }
        
        guard let attributes = json["attributes"] as? [String: Any]
            else { throw SerializationError.missing("attributes") }
        
        guard let name = attributes["name"] as? String
            else { throw SerializationError.missing("name") }
        
        var albumUrl: URL?
        if let artwork = attributes["artwork"] as? [String: Any] {
            
            guard let imageURLTemplate = artwork["url"] as? String
                else { throw SerializationError.missing("imageURL") }
            
            let albumUrlString = imageURLTemplate.replacingOccurrences(of: "{w}", with: "640")
                .replacingOccurrences(of: "{h}", with: "640")
            
            albumUrl = URL(string: albumUrlString)
        }
        
        
        self.init(id: id, name: name, description: "", imageURL: albumUrl)
    }
}

extension Track {
    convenience init(fromAppleMusic json: [String: Any]) throws {
        guard let id = json["id"] as? String
            else { throw SerializationError.missing("id") }
        
        
        
        guard let trackAttributes = json["attributes"] as? [String: Any]
            else { throw SerializationError.missing("trackAttributes") }
        
        var url: URL?
        if let urlString = trackAttributes["url"] as? String {
            url = URL(string: urlString)
        }
        guard let artist = trackAttributes["artistName"] as? String
            else { throw SerializationError.missing("artistName") }
        guard let album = trackAttributes["albumName"] as? String
            else { throw SerializationError.missing("albumName") }
        guard let name = trackAttributes["name"] as? String
            else { throw SerializationError.missing("name") }
        guard let isrc = trackAttributes["isrc"] as? String
            else { throw SerializationError.missing("isrc") }
        guard let artwork = trackAttributes["artwork"] as? [String: Any]
            else { throw SerializationError.missing("artwork") }
        
        var imageURL: URL?
        if let imageURLTemplate = artwork["url"] as? String {
            let imageURLString = imageURLTemplate.replacingOccurrences(of: "{w}", with: "640")
                .replacingOccurrences(of: "{h}", with: "640")
            imageURL = URL(string: imageURLString)
        }
        
        
        
        self.init(serviceId: id, name: name, url: url, local: false, artists: [artist], album: album, imageURL: imageURL, isrcID: isrc)
        
    }
}

extension Playlist {
    convenience init(fromAppleMusicLibrary playlist: AppleMusicLibraryPlaylist) {
        let id = playlist.id
        let name = playlist.attributes?.name
        let description = playlist.attributes?.description?.standard
        var imageURL: URL?
        if let artwork = playlist.attributes?.artwork {
            let imageURLString = artwork.url.replacingOccurrences(of: "{w}", with: String(artwork.width ?? 640))
                .replacingOccurrences(of: "{h}", with: String(artwork.height ?? 640))
            imageURL = URL(string: imageURLString)
        }
        self.init(id: id,
                  name: name!,
                  description: description,
                  imageURL: imageURL)
    }
}



extension Track {
    convenience init(fromAppleMusic track: AppleMusicSong) {
        let id = track.id
        let name = track.attributes?.name
        let url = track.attributes?.url
        //var artists = (track.relationships?.artists?.data.map { $0.attributes?.name ?? nil })
        let artists = [track.attributes!.artistName]
        let album = track.attributes?.albumName
        let isrc = track.attributes?.isrc
        var imageURL: URL?
        if let artwork = track.attributes?.artwork {
            let imageURLString = artwork.url.replacingOccurrences(of: "{w}", with: String(640))
                .replacingOccurrences(of: "{h}", with: String(640))
            imageURL = URL(string: imageURLString)
        }
        
        
        
        
        self.init(serviceId: id,
                  name: name!,
                  url: url,
                  local: false,
                  artists: artists,
                  album: album!,
                  imageURL: imageURL,
                  isrcID: isrc)
    }
    
    convenience init(fromAppleMusicLibrary track: AppleMusicLibrarySong) {
        let id = track.id
        let name = track.attributes?.name
        let url = track.href
        let artists = track.relationships?.artists?.data.map { $0.attributes!.name }
        let album = track.attributes?.albumName
        var imageURL: URL?
        if let artwork = track.attributes?.artwork {
            let imageURLString = artwork.url.replacingOccurrences(of: "{w}", with: String(640))
                .replacingOccurrences(of: "{h}", with: String(640))
            imageURL = URL(string: imageURLString)
        }
        
        
        
        
        self.init(serviceId: id,
                  name: name!,
                  url: url,
                  local: false,
                  artists: artists!,
                  album: album!,
                  imageURL: imageURL,
                  isrcID: nil)
    }
}
