import SwiftUI
import WebKit

struct WebBrowserView: View {
    @State private var address: String = ""
    @State private var urlString: String = ""
    @State private var reloadTrigger: Bool = false
    
    var body: some View {
            VStack(spacing: 0) {
                    HStack {
                TextField("Enter IP:Port (e.g. 192.168.1.100:5063)", text: $address, onCommit: {
                    if !address.isEmpty {
                        urlString = address.hasPrefix("http") ? address : "http://" + address
                        reloadTrigger.toggle()
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            }
            if !urlString.isEmpty {
                WebView(urlString: urlString, reloadTrigger: reloadTrigger)
                    .edgesIgnoringSafeArea(.all)
            } else {
                VStack {
                    Spacer()
                    Text("Enter an IP address and port to load the website")
                        .foregroundColor(.gray)
                    Spacer()
                }
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let urlString: String
    let reloadTrigger: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
