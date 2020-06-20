//
//  SpotifyManager.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import Foundation

class SpotifyManager {
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
                    if let playlist = try? Playlist(json: result) {
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
                    if let track = try? Track(json: result) {
                        tracks.append(track)
                    }
                }
            }
            
            DispatchQueue.main.async {
                completion(tracks)
            }
        }.resume()
    }

}

struct Playlist: Codable, Identifiable {
    var id: String
    var name: String
    var imageURL: String?
    var trackCount: Int?
    var href: String?
    var tracks: [Track]
}

struct Track: Codable, Identifiable {
    var local: Bool
    var id: String
    var artists: [Artist]
    var name: String
    var album: Album
    var isrcID: String?
}


struct Artist: Codable {
    var name: String
}

struct Album: Codable {
    var name: String
    //var imageURL: String
}

enum SerializationError: Error {
    case missing(String)
    case invalid(String, Any)
}


extension Playlist {
    init(json: [String: Any]) throws {
        guard let id = json["id"] as? String
            else { throw SerializationError.missing("id") }
        
        
        
        guard let name = json["name"] as? String
            else { throw SerializationError.missing("name") }
        
        guard let href = json["href"] as? String
            else { throw SerializationError.missing("href") }
        
        guard let imagesJSON = json["images"] as? [[String:Any]]
            else { throw SerializationError.missing("images") }
        
        guard let tracksJSON = json["tracks"] as? [String: Any]
            else { throw SerializationError.missing("tracks") }
        guard let trackCount = tracksJSON["total"] as? Int
            else { throw SerializationError.missing("tracksCount") }

        
        var imageURL: String?
        for image in imagesJSON {
            if image["height"] as? Int == 640 {
                imageURL = image["url"] as? String
            }
        }
        
        if imageURL == nil {
            throw SerializationError.missing("imageURL")
        }
    
        self.name = name
        self.id = id
        self.href = href
        self.imageURL = imageURL!
        self.trackCount = trackCount
    }
}

extension Track {
    init(json: [String: Any]) throws {
        guard let local = json["is_local"] as? Bool
            else { throw SerializationError.missing("is_local") }
        
        guard let track = json["track"] as? [String:Any]
            else { throw SerializationError.missing("track") }
        
        let id = track["id"] as? String
        
        guard let name = track["name"] as? String
            else { throw SerializationError.missing("name") }
        
        guard let artistsJSON = track["artists"] as? [[String:Any]]
            else { throw SerializationError.missing("artists") }
        
        guard let albumJSON = track["album"] as? [String:Any],
            let album = try? Album(json: albumJSON)
            else { throw SerializationError.missing("album") }
        
        
        let externalIdsJSON = track["id"] as? [String: Any]
        if externalIdsJSON != nil {
            guard let isrcID = externalIdsJSON!["isrc"] as? String
                else { throw SerializationError.missing("isrc") }
            self.isrcID = isrcID
        }
        
        var artists = [Artist]()
        for artistJSON in artistsJSON {
            if let artist = try? Artist(json: artistJSON) {
                artists.append(artist)
            }
        }
        
        self.name = name
        self.id = id ?? UUID().uuidString
        self.local = local
        self.artists = artists
        self.album = album
        
    }
}

extension Artist {
    init(json: [String: Any]) throws {
        guard let name = json["name"] as? String
        else { throw SerializationError.missing("name") }
        self.name = name
    }
}

extension Album {
    init(json: [String: Any]) throws {
        guard let name = json["name"] as? String
            else { throw SerializationError.missing("name") }
        self.name = name
    }
}


