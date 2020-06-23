//
//  TransferView.swift
//  music-manager
//
//  Created by Ted Bennett on 23/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI

struct TransferView<ServiceManager: Manager>: View {
    @ObservedObject var playlist: Playlist
    var manager: ServiceManager
    
    var body: some View {
        List(playlist.tracks) { track in
            VStack {
                Text(track.name).foregroundColor(track.isrcID != nil ? .white : .gray)
                Text(track.isrcID ?? "NO ISRC")
            }
        }
    }
}

//struct TransferView_Previews: PreviewProvider {
//    static var previews: some View {
//        TransferView()
//    }
//}
