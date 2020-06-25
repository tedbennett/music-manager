//
//  AddServiceView.swift
//  music-manager
//
//  Created by Ted Bennett on 18/06/2020.
//  Copyright © 2020 Ted Bennett. All rights reserved.
//

import SwiftUI
import WebKit
import OAuth2

struct AddServiceView: View {
    @Binding var spotifyConnected: Bool
    @Binding var appleMusicConnected: Bool
    @State var failedToConnect = false
    var body: some View {
        VStack {
            if !spotifyConnected {
                Spacer()
                Button(action: {
                    SpotifyManager.shared.authorize(completion: { authorised in
                        self.spotifyConnected = authorised
                    })
                }) {
                    Text("Log In to Spotify")
                }
                //.sheet(isPresented: self.$logInToSpotify) {
                    //Webview(closeWindow: self.$logInToSpotify, spotifyConnected: self.$spotifyConnected )
                //}
            }
            if !appleMusicConnected {
                Spacer()
                Button(action: {
                    AppleMusicManager.shared.getAppleMusicAuth() { userToken, _ in
                        if userToken != nil {
                            self.appleMusicConnected = true
                        } else {
                            self.failedToConnect = true
                        }
                    }
                    
                }) {
                    Text("Log In to Apple Music")
                }.alert(isPresented: self.$failedToConnect) {
                Alert(title: Text("Unknown Error"), message: Text("Failed to connect to Apple Music"), dismissButton: .default(Text("OK")))
                }
            }
            Spacer()
        }
    }
}


//struct AddServiceView_Previews: PreviewProvider {
//    @State var spotifyConnected = false
//    static var previews: some View {
//        AddServiceView(spotifyConnected: $spotifyConnected)
//    }
//}

//
//
//
//
//
//class EmbeddedWebviewController: UIViewController, WKNavigationDelegate {
//    var webview = WKWebView()
//    public var delegate: Coordinator? = nil
//
//    init(coordinator: Coordinator) {
//        self.delegate = coordinator
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required init?(coder: NSCoder) {
//        self.webview = WKWebView()
//        super.init(coder: coder)
//    }
//
//
//    public func loadUrl(_ url: URL) {
//        webview.load(URLRequest(url: url))
//    }
//
//    override func loadView() {
//        self.webview.navigationDelegate = self
//        view = webview
//    }
//
//    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
//        guard let url = (navigationResponse.response as! HTTPURLResponse).url else {
//            decisionHandler(.cancel)
//            return
//        }
//        if url.host == "www.tedbennett.co.uk" {
//            if let query = url.query {
//                var components = URLComponents()
//                components.query = query
//
//                for item in components.queryItems! {
//                    if item.name == "code" {
//                        self.delegate?.finishAuth(sender: self.webview, code: item.value!)
//                    }
//                }
//            }
//            if let fragment = url.fragment {
//                var components = URLComponents()
//                components.query = fragment
//                for item in components.queryItems! {
//                    if item.name == "access_token" {
//                        self.delegate?.finishAuth(sender: self.webview, code: item.value!)
//                    }
//                }
//
//
//            }
//        }
//        decisionHandler(.allow)
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }
//}
//
//struct Webview : UIViewControllerRepresentable {
//    @Binding var closeWindow: Bool
//    @Binding var spotifyConnected: Bool
//
//    func makeCoordinator() -> Coordinator {
//        Coordinator(self)
//    }
//    func makeUIViewController(context: Context) -> EmbeddedWebviewController {
//        let webViewController = EmbeddedWebviewController(coordinator: context.coordinator)
//        webViewController.loadUrl(URL(string: SpotifyManager.shared.authURL)!)
//        //done.toggle()
//        return webViewController
//    }
//
//    func updateUIViewController(_ uiViewController: EmbeddedWebviewController, context: UIViewControllerRepresentableContext<Webview>) {
//
//    }
//
//    func finishAuth(code: String) {
//        SpotifyManager.shared.authToken = code
//        self.spotifyConnected = true
//        self.closeWindow.toggle()
//    }
//
//}
//
//class Coordinator: NSObject {
//    var webview: Webview
//
//    init(_ webview: Webview) {
//        self.webview = webview
//    }
//
//    @objc func finishAuth(sender: WKWebView, code: String) {
//        webview.finishAuth(code: code)
//    }
//}
//
