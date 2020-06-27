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

    var baseURL = "https://api.music.apple.com/v1/"
    var developerToken = AppleMusicEnvironment.musicToken
    var userToken: String? = KeychainWrapper.standard.string(forKey: "appleMusicUserToken")
    var storefront: String? = KeychainWrapper.standard.string(forKey: "appleMusicStorefront")
    
    var controller = SKCloudServiceController()
    
    static let shared = AppleMusicManager()
    
    private init() {}
    
    func getAppleMusicAuth(completion: @escaping (String?, Error?) -> Void) {
        SKCloudServiceController.requestAuthorization { status in
            if status == .authorized {
                self.controller.requestCapabilities { capabilities, error in
                    if capabilities.contains(.musicCatalogPlayback) {
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
        guard let url = URL(string: baseURL + "me/storefront") else { return }
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
        return Promise { seal in
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(developerToken)",
                "Music-User-Token": userToken!
            ]
            AF.request(baseURL + "me/library/playlists", headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(AppleMusicResponse<AppleMusicLibraryPlaylist>.self, from: data!)
                                seal.fulfill(decoded.data.map { Playlist(fromAppleMusicLibrary: $0 )})
                            } catch {
                                seal.reject(error)
                            }
                            
                        case .failure(let error):
                            seal.reject(error)
                    }
            }
        }
    }
    
    func fetchCatalogIdsFromPlaylist(id: String) -> Promise<[String]> {
        return Promise { seal in
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(developerToken)",
                "Music-User-Token": userToken!
            ]
            AF.request(baseURL + "me/library/playlists/\(id)/tracks", headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(AppleMusicResponse<AppleMusicLibrarySong>.self, from: data!)
                                seal.fulfill(decoded.data.map { $0.attributes?.playParams?.catalogId as! String })
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
        return Promise { seal in
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(developerToken)",
                "Music-User-Token": userToken!
            ]
            let parameters = [
                "ids": ids.joined(separator: ","),
                "include": "artists"
            ]
            AF.request(baseURL + "catalog/\(storefront!)/songs", parameters: parameters, headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(AppleMusicResponse<AppleMusicSong>.self, from: data!)
                                seal.fulfill(decoded.data.map { Track(fromAppleMusic: $0) })
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
                "Authorization": "Bearer \(developerToken)",
                "Music-User-Token": userToken!
            ]
            AF.request(baseURL + "catalog/\(storefront!)/songs/\(id)", headers: headers)
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
    
    func fetchTracksFromIsrcIds(isrcIds: [String]) -> Promise<[Track]> {
        return Promise { seal in
            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(developerToken)",
                "Music-User-Token": userToken!
            ]
            let parameters = ["filter[isrc]": isrcIds.joined(separator: ",")]
            
            AF.request(baseURL + "catalog/\(storefront ?? "us")/songs", parameters: parameters, headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                        case .success(let data):
                            do {
                                let decoded = try JSONDecoder().decode(AppleMusicResponse<AppleMusicSong>.self, from: data!)
                                seal.fulfill(decoded.data.map { Track(fromAppleMusic: $0) })
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
            
            AF.request(baseURL + "catalog/\(storefront ?? "us")/search", parameters: parameters, headers: headers)
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
    
    func getPlaylistTracks(id: String, completion: @escaping ([Track]) -> ()) {
        if userToken == nil || SKCloudServiceController.authorizationStatus() != .authorized {
            return
        }
        let url = URL(string: baseURL + "me/library/playlists/\(id)/tracks")
        
        
        var request = URLRequest(url: url!)
        request.setValue("Bearer " + developerToken, forHTTPHeaderField: "Authorization")
        request.setValue(userToken!, forHTTPHeaderField: "Music-User-Token")
        
        URLSession.shared.dataTask(with: request) { (data, _, _) in
            
            var trackIds = [String]()
            
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let data = json["data"] as! [[String: Any]]
                for trackData in data {
                    let trackAttributes = trackData["attributes"] as! [String: Any]
                    let playParams = trackAttributes["playParams"] as! [String: Any]
                    let id = playParams["catalogId"] as! String
                    
                    trackIds.append(id)
                    
                }
                guard var tracksUrl = URLComponents(string: self.baseURL + "catalog/\(self.storefront!)/songs") else {return}
                
                tracksUrl.queryItems = [URLQueryItem(name: "ids", value: trackIds.joined(separator: ","))]
                
                var request = URLRequest(url: tracksUrl.url!)
                request.setValue("Bearer " + self.developerToken, forHTTPHeaderField: "Authorization")
                request.setValue(self.userToken!, forHTTPHeaderField: "Music-User-Token")
                URLSession.shared.dataTask(with: request) { (data, _, _) in
                    var tracks = [Track]()
                    
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
            
        }.resume()
    }
    
    func getIsrcID(id: String, completion: @escaping (Track) -> ()) {
        if userToken == nil || storefront == nil {
            return
        }
        guard let url = URL(string: baseURL + "catalog/\(storefront!)/songs/\(id)") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer " + developerToken, forHTTPHeaderField: "Authorization")
        //request.setValue(userToken!, forHTTPHeaderField: "Music-User-Token")
        
        
        var track: Track?
        URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                for case let data in json["data"] as! [[String: Any]] {
                    track = try? Track(fromAppleMusic: data)
                }
                
            }
            DispatchQueue.main.async {
                if track != nil {
                    completion(track!)
                }
            }
        }.resume()
    }
    
    func getTracksFromIsrcID(isrcs: [String], completion: @escaping ([Track]) -> ()) {
        guard var url = URLComponents(string: baseURL + "catalog/\(storefront ?? "us")/songs") else { return }
        
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
    
    func getSearchResults(for search: String, completion: @escaping ([Track]) -> ()) {
        guard var url = URLComponents(string: baseURL + "catalog/\(storefront ?? "us")/search") else { return }
        let escapedString = search.replacingOccurrences(of: " ", with: "+")
        url.queryItems = [URLQueryItem(name: "term", value: escapedString), URLQueryItem(name: "types", value: "songs"), URLQueryItem(name: "limit", value: "5")]
        if url.url == nil {
            return
        }
        var request = URLRequest(url: url.url!)
        
        request.setValue("Bearer " + developerToken, forHTTPHeaderField: "Authorization")
        
        var tracks = [Track]()
        URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                if let results = json["results"] as? [String: Any] {
                    let songsJSON = results["songs"] as! [String: Any]
                    let songsData = songsJSON["data"] as! [[String:Any]]
                    for data in songsData {
                        if let track = try? Track(fromAppleMusic: data) {
                            tracks.append(track)
                        }
                    }
                }
            }
            DispatchQueue.main.async {
                completion(tracks)
            }
        }.resume()
    }
    
    func transferPlaylistToAppleMusic(name: String, with tracks: [Track], completion: @escaping () -> Void) {
        var isrcIds = [String]()
        for track in tracks {
            if let isrcId = track.isrcID {
                isrcIds.append(isrcId)
            }
        }
        getTracksFromIsrcID(isrcs: isrcIds, completion: { tracks in
            guard let url = URL(string: self.baseURL + "me/library/playlists") else { return }
            
            let attributes = ["name": name]
            var songObjects = [[String: Any]]()
            
            for track in tracks {
                songObjects.append( ["id": track.serviceId, "type": "songs"])
            }
            
            let httpBody = [
                "attributes": attributes,
                
//                "relationships": [
//                    "tracks": [
//                        "data": songObjects
//                    ]
//                ]
                ] as [String : Any]
            let bodyData = try? JSONSerialization.data(withJSONObject: httpBody)
            var request = URLRequest(url: url)
            request.httpBody = bodyData

            request.setValue("Bearer " + self.developerToken, forHTTPHeaderField: "Authorization")
            request.setValue(self.userToken!, forHTTPHeaderField: "Music-User-Token")
            
            request.httpMethod = "POST"
            
            URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
                if let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let data = json["data"] as? [[String: Any]] {
                        let playlistId = data[0]["id"] as! String
                        let addTracksURL = url.appendingPathComponent("\(playlistId)/tracks")
                        let httpBody = [
                            "data": songObjects
                        ]
                        let bodyData = try? JSONSerialization.data(withJSONObject: httpBody)
                        var addTracksRequest = URLRequest(url: addTracksURL)
                        addTracksRequest.httpBody = bodyData
                        
                        addTracksRequest.setValue("Bearer " + self.developerToken, forHTTPHeaderField: "Authorization")
                        addTracksRequest.setValue(self.userToken!, forHTTPHeaderField: "Music-User-Token")
                        
                        addTracksRequest.httpMethod = "POST"
                        URLSession.shared.dataTask(with: addTracksRequest) { (data, urlResponse, error) in
                            completion()
                        }
                    }
                }
                if error == nil {
                    
                }
            }.resume()
        })
        
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
