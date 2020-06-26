//
//  SpotifyObjects.swift
//  music-manager
//
//  Created by Ted Bennett on 26/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import Foundation

struct SpotifyAlbum: Decodable {
    var albumType: String?
    var artists: [SpotifySimpleArtist]
    var availableMarkets: [String]
    var externalIds: SpotifyExternalId
    var externalUrls: SpotifyExternalUrl
    var genres: [String]
    var href: URL
    var id: String
    var images: [SpotifyImage]
    var label: String
    var name: String
    var popularity: Int
    var releaseDate: String
    var releaseDatePrecision: String
    var tracks: SpotifyPagingObject<SpotifySimpleTrack>
    var type: String
    var uri: String
    
    private enum CodingKeys : String, CodingKey {
        case albumType = "album_type",
        availableMarkets = "available_markets",
        externalIds = "external_ids",
        externalUrls = "external_urls",
        releaseDate = "release_date",
        releaseDatePrecision = "release_date_precision",
        artists,
        genres,
        href,
        id,
        images,
        label,
        name,
        popularity,
        tracks,
        type,
        uri
    }
}

struct SpotifySimpleAlbum: Decodable {
    var albumType: String?
    var artists: [SpotifySimpleArtist]
    var availableMarkets: [String]
    var externalUrls: SpotifyExternalUrl
    var href: URL
    var id: String
    var images: [SpotifyImage]
    var name: String
    var releaseDate: String
    var releaseDatePrecision: String
    var type: String
    var uri: String
    
    private enum CodingKeys : String, CodingKey {
        case albumType = "album_type",
        availableMarkets = "available_markets",
        externalUrls = "external_urls",
        releaseDate = "release_date",
        releaseDatePrecision = "release_date_precision",
        artists,
        href,
        id,
        images,
        name,
        type,
        uri
    }
}

struct SpotifyArtist: Decodable {
    var externalUrls: SpotifyExternalUrl
    var genres: [String]
    var href: URL
    var id: String
    var images: [SpotifyImage]
    var name: String
    var popularity: Int
    var type: String
    var uri: String
    
    private enum CodingKeys : String, CodingKey {
        case externalUrls = "external_urls",
        genres,
        href,
        id,
        images,
        name,
        popularity,
        type,
        uri
    }
}

struct SpotifySimpleArtist: Decodable {
    var externalUrls: SpotifyExternalUrl
    var href: URL
    var id: String
    var name: String
    var type: String
    var uri: String
    
    private enum CodingKeys : String, CodingKey {
        case externalUrls = "external_urls",
        href,
        id,
        name,
        type,
        uri
    }
}

struct SpotifyExternalId: Decodable {
    var isrc: String?
}

struct SpotifyExternalUrl: Decodable {
    var spotify: URL?
}

struct SpotifyImage: Decodable {
    var height: Int?
    var width: Int?
    var url: URL
}

struct SpotifyPagingObject<Object: Decodable>: Decodable {
    var href: URL
    var items: [Object]
    var limit: Int
    var next: URL?
    var offset: Int
    var previous: URL?
    var total: Int
}

struct SpotifyPlaylist: Decodable {
    var collaborative: Bool
    var description: String?
    var externalUrls: SpotifyExternalUrl
    var href: String
    var id: String
    var images: [SpotifyImage]
    var name: String
    var owner: SpotifyUserPublic
    var isPublic: Bool
    var snapshotId: String
    var tracks: SpotifyPlaylistTrackBrief
    var type: String
    var uri: String
    
    private enum CodingKeys : String, CodingKey {
        case externalUrls = "external_urls",
        isPublic = "public",
        snapshotId = "snapshot_id",
        collaborative,
        description,
        href,
        id,
        images,
        name,
        owner,
        tracks,
        type,
        uri
    }
}

struct SpotifyPlaylistTrack: Decodable {
    var addedAt: String?
    var addedBy: SpotifyUserPublic?
    var isLocal: Bool
    var track: SpotifyTrack
    
    private enum CodingKeys : String, CodingKey {
        case addedAt = "added_at",
        addedBy = "added_by",
        isLocal = "is_local",
        track
    }
}

struct SpotifyPlaylistTrackBrief: Decodable {
    var total: Int
    var href: URL
}

struct SpotifyTrack: Decodable {
    var album: SpotifySimpleAlbum
    var artists: [SpotifySimpleArtist]
    var availableMarkets: [String]
    var discNumber: Int
    var durationMs: Int
    var explicit: Bool
    var externalIds: SpotifyExternalId?
    var externalUrls: SpotifyExternalUrl
    var href: URL
    var id: String?
    var name: String
    var popularity: Int
    var previewUrl: URL?
    var trackNumber: Int
    var type: String
    var uri: String
    var isLocal: Bool
    
    private enum CodingKeys : String, CodingKey {
        case availableMarkets = "available_markets",
        externalUrls = "external_urls",
        externalIds = "external_ids",
        discNumber = "disc_number",
        durationMs = "duration_ms",
        previewUrl = "preview_url",
        trackNumber = "track_number",
        isLocal = "is_local",
        album,
        artists,
        explicit,
        href,
        id,
        name,
        popularity,
        type,
        uri
    }
}

struct SpotifySearch: Decodable {
    var albums: SpotifyPagingObject<SpotifySimpleAlbum>?
    var artists: SpotifyPagingObject<SpotifyArtist>?
    var playlists: SpotifyPagingObject<SpotifyPlaylist>?
    var tracks: SpotifyPagingObject<SpotifyTrack>?
}

struct SpotifySimpleTrack: Decodable {
    var artists: [SpotifySimpleArtist]
    var availableMarkets: [String]
    var discNumber: Int
    var durationMs: Int
    var explicit: Bool
    var externalUrls: SpotifyExternalUrl
    var href: URL
    var id: String
    var name: String
    var previewUrl: URL?
    var trackNumber: Int
    var type: String
    var uri: String
    var isLocal: Bool
    
    private enum CodingKeys : String, CodingKey {
        case availableMarkets = "available_markets",
        externalUrls = "external_urls",
        discNumber = "disc_number",
        durationMs = "duration_ms",
        previewUrl = "preview_url",
        trackNumber = "track_number",
        isLocal = "is_local",
        artists,
        explicit,
        href,
        id,
        name,
        type,
        uri
    }
}

struct SpotifyUserPrivate: Decodable {
    var country: String
    var displayName: String
    var email: String
    var externalUrls: SpotifyExternalUrl
    var href: URL
    var id: String
    var images: [SpotifyImage]
    var product: String
    var type: String
    var uri: String
    
    private enum CodingKeys : String, CodingKey {
        case displayName = "display_name",
        externalUrls = "external_urls",
        country,
        email,
        href,
        id,
        images,
        product,
        type,
        uri
    }
}

struct SpotifyUserPublic: Decodable {
    var displayName: String?
    var externalUrls: SpotifyExternalUrl
    var href: URL
    var id: String
    var images: [SpotifyImage]?
    var type: String
    var uri: String
    
    private enum CodingKeys : String, CodingKey {
        case displayName = "display_name",
        externalUrls = "external_urls",
        href,
        id,
        images,
        type,
        uri
    }
}
