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
                        }
                    }
                }
            }
        }
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
        guard var url = URLComponents(string: baseURL + "me/library/playlists/" + id) else { return }
        
        
        
        url.queryItems = [
            URLQueryItem(name: "include", value: "tracks")
        ]
        
        var request = URLRequest(url: url.url!)
        request.setValue("Bearer " + developerToken, forHTTPHeaderField: "Authorization")
        request.setValue(userToken!, forHTTPHeaderField: "Music-User-Token")
        
        URLSession.shared.dataTask(with: request) { (data, _, _) in
            
            var tracks = [Track]()
            
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                let data = json["data"] as! [[String: Any]]
                let relationships = data[0]["relationships"] as! [String: Any]
                let tracksJSON = relationships["tracks"] as! [String: Any]
                let trackData = tracksJSON["data"] as! [[String: Any]]
                for trackJSON in trackData {
                    let track = try! Track(fromAppleMusic: trackJSON)
                    tracks.append(track)
                    
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
    init(fromAppleMusic json: [String: Any]) throws {
        guard let id = json["id"] as? String
            else { throw SerializationError.missing("id") }
        guard let trackAttributes = json["attributes"] as? [String: Any]
            else { throw SerializationError.missing("trackAttributes") }
        
        guard let artist = trackAttributes["artistName"] as? String
            else { throw SerializationError.missing("artistName") }
        guard let album = trackAttributes["albumName"] as? String
            else { throw SerializationError.missing("albumName") }
        guard let name = trackAttributes["name"] as? String
            else { throw SerializationError.missing("name") }
        
        //        guard let isrc = trackAttributes["isrc"] as? String
        //            else { throw SerializationError.missing("isrc") }
        
        guard let artwork = trackAttributes["artwork"] as? [String: Any]
            else { throw SerializationError.missing("artwork") }
        
        guard let imageURL = artwork["url"] as? String
            else { throw SerializationError.missing("imageURL") }
        
        
        self.name = name
        self.id = id
        //self.isrcID = isrc
        self.artists = [Artist(name: artist)]
        self.album = Album(name: album, imageURL: imageURL)
        self.local = false
    }
}
