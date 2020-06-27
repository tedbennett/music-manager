//
//  ImageLoader.swift
//  music-manager
//
//  Created by Ted Bennett on 27/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import Foundation
import SwiftUI
import Combine


struct ImageView: View {
    let url: URL
    var normalSize: Bool
    
    init(url: URL, normalSize: Bool = true) {
        self.url = url
        self.normalSize = normalSize
    }
    var body: some View {
        VStack(alignment: .center) {
            if normalSize {
                ImageViewContainer(imageUrl: url)
            } else {
                LargeImageViewContainer(imageUrl: url)
            }
        }
    }
    
    struct ImageViewContainer: View {
        @ObservedObject var remoteImageURL: RemoteImageURL
        
        init(imageUrl: URL) {
            remoteImageURL = RemoteImageURL(imageURL: imageUrl)
        }
        
        var body: some View {
            Image(uiImage: UIImage(data: remoteImageURL.data) ?? UIImage())
                .resizable()
                .cornerRadius(4)
                .frame(width: 75.0, height: 75.0)
        }
    }
    struct LargeImageViewContainer: View {
        @ObservedObject var remoteImageURL: RemoteImageURL
        
        init(imageUrl: URL) {
            remoteImageURL = RemoteImageURL(imageURL: imageUrl)
        }
        
        var body: some View {
            Image(uiImage: UIImage(data: remoteImageURL.data) ?? UIImage())
                .resizable()
                .cornerRadius(5)
                .frame(minWidth: 100, idealWidth: 300, maxWidth: 300, minHeight: 100, idealHeight: 300, maxHeight: 300, alignment: .center)
        }
    }
    
    class RemoteImageURL: ObservableObject {
        var didChange = PassthroughSubject<Data, Never>()
        @Published var data = Data() {
            didSet {
                didChange.send(data)
            }
        }
        init(imageURL: URL) {
            URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
                guard let data = data else { return }
                
                DispatchQueue.main.async { self.data = data }
                
            }.resume()
        }
    }
    
}

