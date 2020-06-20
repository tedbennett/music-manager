//
//  AppleMusicManager.swift
//  music-manager
//
//  Created by Ted Bennett on 19/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import Foundation
import StoreKit

class AppleMusicManager {
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
        if userToken == nil || SKCloudServiceController.authorizationStatus() != .authorized
        {
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
                    if let playlist = try? Playlist(appleJson: result) {
                        playlists.append(playlist)
                        
                    }
                }
            }
            DispatchQueue.main.async {
                completion(playlists)
            }
        }.resume()
    }
}

extension Playlist {
    init(appleJson: [String: Any]) throws {
        guard let id = appleJson["id"] as? String
            else { throw SerializationError.missing("id") }
        
        guard let attributes = appleJson["attributes"] as? [String: Any]
            else { throw SerializationError.missing("attributes") }
        
        guard let name = attributes["name"] as? String
            else { throw SerializationError.missing("name") }
        
        self.name = name
        self.id = id
    }
}
