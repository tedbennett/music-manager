//
//  AppleMusicManager.swift
//  music-manager
//
//  Created by Ted Bennett on 19/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import Foundation
import StoreKit

class AppleMusicManager: Manager {
    
    var baseURL = "https://api.music.apple.com/v1/"
    var developerToken = Environment.AppleMusic.musicToken
    var userToken: String?
    var storefront: String?
    
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
        request.setValue("Bearer " + developerToken, forHTTPHeaderField: "Authorization")
        request.setValue(userToken!, forHTTPHeaderField: "Music-User-Token")
        
        
        URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
            
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                for case let data in json["data"] as! [[String: Any]] {
                    let storefront = data["id"] as! String
                    self.storefront = storefront
                }
            }
        }.resume()
        
    }
    
    
    func getUserPlaylists(completion: @escaping ([Playlist]) -> Void) {
        print(SKCloudServiceController.authorizationStatus())
        if userToken == nil || SKCloudServiceController.authorizationStatus() != .authorized {
            return
        }
        guard let url = URL(string: baseURL + "me/library/playlists") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer " + developerToken, forHTTPHeaderField: "Authorization")
        request.setValue(userToken!, forHTTPHeaderField: "Music-User-Token")
        
        
        URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
            var playlists = [Playlist]()
            
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                for case let result in json["data"] as! [[String: Any]] {
                    if let playlist = try? Playlist(fromAppleMusic: result) {
                        playlists.append(playlist)
                        
                    }
                }
            }
            DispatchQueue.main.async {
                completion(playlists)
            }
        }.resume()
    }
    
    func getPlaylistTracks(id: String, completion: @escaping ([Track]) -> ()) {
        if userToken == nil || SKCloudServiceController.authorizationStatus() != .authorized {
            return
        }
        let url = URL(string: baseURL + "me/library/playlists/" + id + "/tracks")
        
        
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
        request.setValue(userToken!, forHTTPHeaderField: "Music-User-Token")
        
        
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
        if userToken == nil || storefront == nil {
            return
        }
        guard var url = URLComponents(string: baseURL + "catalog/\(storefront!)/songs") else { return }
        
        url.queryItems = [URLQueryItem(name: "filter[isrc]", value: isrcs.joined(separator: ","))]
        
        var request = URLRequest(url: url.url!)
        request.setValue("Bearer " + developerToken, forHTTPHeaderField: "Authorization")
        request.setValue(userToken!, forHTTPHeaderField: "Music-User-Token")
        
        var isrcIDs = isrcs
        var tracks = [Track]()
        URLSession.shared.dataTask(with: request) { (data, urlResponse, error) in
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                for case let data in json["data"] as! [[String: Any]] {
                    if let track = try? Track(fromAppleMusic: data) {
                        if track.isrcID != nil && isrcIDs.contains(track.isrcID!) {
                            tracks.append(track)
                            isrcIDs.removeAll(where: {
                                isrc in isrc == track.isrcID
                            })
                        }
                    }
                }
                
            }
            DispatchQueue.main.async {
                completion(tracks)
            }
        }.resume()
        
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
        
        self.init(id: id, name: name)
    }
}

extension Track {
    convenience init(fromAppleMusic json: [String: Any]) throws {
        guard let id = json["id"] as? String
            else { throw SerializationError.missing("id") }
        
        
        
        guard let trackAttributes = json["attributes"] as? [String: Any]
            else { throw SerializationError.missing("trackAttributes") }
        
        guard let url = trackAttributes["url"] as? String
            else { throw SerializationError.missing("url") }
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
        
        guard let imageURL = artwork["url"] as? String
            else { throw SerializationError.missing("imageURL") }
        
        self.init(id: id, name: name, url: url, local: false, artists: [Artist(name: artist)], album: Album(name: album, imageURL: imageURL), isrcID: isrc)
        
    }
}
