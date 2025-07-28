import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

struct WebViewScreen: View {
    private let urlString = "https://www.cheryjaguarlandrover.com/en/" // Replace with your desired URL
    var body: some View {
        VStack {
            if let url = URL(string: urlString) {
                WebView(url: url)
            } else {
                Text("Invalid URL")
            }
        }
        .navigationTitle("URL Web")
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct WebViewScreen_Previews: PreviewProvider {
    static var previews: some View {
        WebViewScreen()
    }
} 
