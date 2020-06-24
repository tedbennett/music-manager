//
//  SpotifyManager.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import Foundation

class SpotifyManager: Manager {
    
    var baseURL = "https://api.spotify.com/v1/"
    var baseAuthURL = "https://accounts.spotify.com/authorize"
    var clientID = Environment.Spotify.clientID
    var responseType = "token"
    var redirectURL = "https://www.tedbennett.co.uk/"
    var scope = "user-read-private%20user-read-email"
    var authURL : String { baseAuthURL + "?client_id=" + clientID + "&response_type=" + responseType + "&redirect_uri=" + redirectURL }
    
    var authToken: String?
    
    static let shared = SpotifyManager()
    
    private init() {}
    
    func getUserPlaylists(completion: @escaping ([Playlist]) -> ()) {
        if authToken == nil {
            return
        }
        guard let url = URL(string: baseURL + "me/playlists") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer " + authToken!, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, _, _) in
            var playlists = [Playlist]()
            
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                for case let result in json["items"] as! [[String: Any]] {
                    if let playlist = try? Playlist(fromSpotify: result) {
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
        if authToken == nil {
            return
        }
        guard let url = URL(string: baseURL + "playlists/" + id + "/tracks") else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer " + authToken!, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, _, _) in
            //            let jsonResult = try! JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers)
            //
            //            print(jsonResult)
            
            var tracks = [Track]()
            
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                for case let result in json["items"] as! [[String: Any]] {
                    let local = result["is_local"] as! Bool
                    
                    let track = result["track"] as! [String:Any]
                    
                    if let track = try? Track(fromSpotify: track) {
                        track.local = local
                        tracks.append(track)
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(tracks)
            }
        }.resume()
    }
    
    func getIsrcID(id: String, completion: @escaping (Track) -> ()) {
        if authToken == nil {
            return
        }
        guard let url = URL(string: baseURL + "tracks/" + id) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer " + authToken!, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, _, _) in
            var track: Track?
            
            if let data = data,
                let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                track = try? Track(fromSpotify: json)
                
            }
            
            DispatchQueue.main.async {
                if track != nil {
                    completion(track!)
                }
            }
        }.resume()
    }
    
    func getTracksFromIsrcID(isrcs: [String], completion: @escaping (([Track?]) -> ())) {
        if authToken == nil {
            return
        }
        var tracks = [Track?]()
        for isrc in isrcs {
            
            guard var url = URLComponents(string: baseURL + "search") else { return }
            
            url.queryItems = [URLQueryItem(name: "q", value: "isrc:\(isrc)"), URLQueryItem(name: "type", value: "track"), URLQueryItem(name: "limit", value: "1")]
            var request = URLRequest(url: url.url!)
            request.setValue("Bearer " + authToken!, forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { (data, _, _) in
                if let data = data,
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    let tracksJSON = json["tracks"] as! [String: Any]
                    
                    let items = tracksJSON["items"] as! [[String:Any]]
                    let track = try? Track(fromSpotify: items[0])
                    tracks.append(track)
                    
                }
                DispatchQueue.main.async {
                    completion(tracks)
                }
            }.resume()
            
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
        
        guard let isrcID = externalIdsJSON!["isrc"] as? String
            else { throw SerializationError.missing("isrc") }
        
        
        var artists = [String]()
        for artist in artistsJSON {
            if let artistName = artist["name"] as? String {
                artists.append(artistName)
            }
        }
        self.init(id: id ?? UUID().uuidString, name: name, url: url, local: false, artists: artists, album: albumName, imageURL: imageURL, isrcID: isrcID)
    }
}



