//
//  SpotifyManager.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import Foundation

class SpotifyManager {
    
    var baseURL = "https://accounts.spotify.com/authorize"
    var clientID = Environment.clientID
    var secretID = Environment.secretID
    var responseType = "token"
    var redirectURL = "https://www.tedbennett.co.uk/"
    var scope = "user-read-private%20user-read-email"
    var authURL : String { baseURL + "?client_id=" + clientID + "&response_type=" + responseType + "&redirect_uri=" + redirectURL }
    
    var authToken: String?
    
    static let shared = SpotifyManager()
    
    private init() {}
    
    
}
