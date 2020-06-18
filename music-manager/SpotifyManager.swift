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
    var clientID = Environment.clientID
    var secretID = Environment.secretID
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
            let playlists = try! JSONDecoder().decode(SpotifyResponse<Playlist>.self, from: data!)
            DispatchQueue.main.async {
                completion(playlists.items)
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
            let tracks = try! JSONDecoder().decode(SpotifyResponse<TrackParent>.self, from: data!)
            DispatchQueue.main.async {
                completion(tracks.items.map { item in
                    return item.track
                })
            }
        }.resume()
    }

}

struct SpotifyResponse<Type: Codable>: Codable {
    var items: [Type]
}

struct Playlist: Codable, Identifiable {
    var id: String
    var name: String
    var tracks: PlaylistItems
    
    struct PlaylistItems: Codable {
        var total: Int
    }
}
struct TrackParent: Codable {
    var track: Track
}
struct Track: Codable, Identifiable {
    var name: String
    var id: String
    var artists: [Artist]
    var album: Album
}

struct Artist: Codable {
    var name: String
}

struct Album: Codable {
    var name: String
}



