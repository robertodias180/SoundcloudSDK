//
//  PlaylistRequest.swift
//  
//
//  Created by Kevin DELANNOY on 06/08/15.
//
//

import Foundation

public extension Playlist {
    static let BaseURL = URL(string: "https://api.soundcloud.com/playlists")!

    /**
    Load playlist with a specific identifier

    - parameter identifier:  The identifier of the playlist to load
    - parameter secretToken: The secret token to access the playlist or nil
    - parameter completion:  The closure that will be called when playlist is loaded or upon error
    */
    public static func playlist(identifier: Int, secretToken: String? = nil, completion: (SimpleAPIResponse<Playlist>) -> Void) {
        guard let clientIdentifier = Soundcloud.clientIdentifier else {
            completion(SimpleAPIResponse(.CredentialsNotSet))
            return
        }

        let url = try! BaseURL.appendingPathComponent("\(identifier)")

        var parameters = ["client_id": clientIdentifier]
        if let secretToken = secretToken {
            parameters["secret_token"] = secretToken
        }

        let request = Request(url: url, method: .GET, parameters: parameters, parse: {
            if let playlist = Playlist(JSON: $0) {
                return .success(playlist)
            }
            return .failure(.Parsing)
            }, completion: { result in
                completion(SimpleAPIResponse(result))
        })
        request.start()
    }

    #if os(iOS) || os(OSX)
    /**
     Creates a playlist with a name and a specific sharing access

     - parameter name:          The name of the playlist
     - parameter sharingAccess: The required sharing access
     - parameter completion:    The closure that will be called when playlist is created or upon error
     */
    public static func create(withName name: String, sharingAccess: SharingAccess, completion: (SimpleAPIResponse<Playlist>) -> Void) {
        guard let clientIdentifier = Soundcloud.clientIdentifier else {
            completion(SimpleAPIResponse(.CredentialsNotSet))
            return
        }

        guard let oauthToken = Soundcloud.session?.accessToken else {
            completion(SimpleAPIResponse(.NeedsLogin))
            return
        }

        let queryStringParameters = ["client_id": clientIdentifier, "oauth_token": oauthToken]
        let url = try! BaseURL.appendingPathComponent(queryStringParameters.queryString)

        let parameters = ["playlist[title]": name,
            "playlist[sharing]": sharingAccess.rawValue]

        let request = Request(url: url, method: .POST, parameters: parameters, parse: {
            if let playlist = Playlist(JSON: $0) {
                return .success(playlist)
            }
            return .failure(.Parsing)
        }) { result in
            completion(SimpleAPIResponse(result))
        }
        request.start()
    }

    public func addTrack(withIdentifier identifier: Int, completion: (SimpleAPIResponse<Playlist>) -> Void) {
        addTracks(withIdentifiers: [identifier], completion: completion)
    }

    public func addTracks(withIdentifiers identifiers: [Int], completion: (SimpleAPIResponse<Playlist>) -> Void) {
        updateTracks(withIdentifiers: tracks.map { $0.identifier } + identifiers, completion: completion)
    }

    public func removeTrack(withIdentifier identifier: Int, completion: (SimpleAPIResponse<Playlist>) -> Void) {
        removeTracks(withIdentifiers: [identifier], completion: completion)
    }

    public func removeTracks(withIdentifiers identifiers: [Int], completion: (SimpleAPIResponse<Playlist>) -> Void) {
        updateTracks(withIdentifiers: tracks
            .map { $0.identifier }
            .filter { !identifiers.contains($0) }, completion: completion)
    }

    private func updateTracks(withIdentifiers identifiers: [Int], completion: (SimpleAPIResponse<Playlist>) -> Void) {
        guard let clientIdentifier = Soundcloud.clientIdentifier else {
            completion(SimpleAPIResponse(.CredentialsNotSet))
            return
        }

        guard let oauthToken = Soundcloud.session?.accessToken else {
            completion(SimpleAPIResponse(.NeedsLogin))
            return
        }

        let queryStringParameters = ["client_id": clientIdentifier, "oauth_token": oauthToken]
        let url = try! Playlist.BaseURL.appendingPathComponent("\(identifier)")
            .appendingQueryString(queryStringParameters.queryString)

        let parameters = [
            "playlist": [
                "tracks": identifiers.map { ["id": "\($0)"] }
            ]
        ]
        guard let JSONEncoded = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            completion(SimpleAPIResponse(.Parsing))
            return
        }

        let request = Request(url: url, method: .PUT, parameters: JSONEncoded, headers: ["Content-Type": "application/json"], parse: {
            if let playlist = Playlist(JSON: $0) {
                return .success(playlist)
            }
            return .failure(.Parsing)
        }) { result in
            completion(SimpleAPIResponse(result))
        }
        request.start()
    }
    #endif
}
