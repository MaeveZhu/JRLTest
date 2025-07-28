import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("WebView: Started loading")
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView: Finished loading")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView: Failed to load - \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView: Failed provisional navigation - \(error.localizedDescription)")
        }
    }
}

struct WebViewScreen: View {
    @State private var isLoading = true
    @State private var hasError = false
    @State private var errorMessage = ""
    
    private let urlString = "https://www.cheryjaguarlandrover.com/en/"
    
    var body: some View {
        VStack {
            if let url = URL(string: urlString) {
                ZStack {
                    WebView(url: url)
                        .onAppear {
                            isLoading = true
                            hasError = false
                        }
                    
                    if isLoading {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .onAppear {
                                // Hide loading after a reasonable time
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    isLoading = false
                                }
                            }
                    }
                    
                    if hasError {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("加载失败")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(errorMessage)
                                .font(.body)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Button("重试") {
                                hasError = false
                                isLoading = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("无效的URL")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("无法解析网址: \(urlString)")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .navigationTitle("网页浏览")
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct WebViewScreen_Previews: PreviewProvider {
    static var previews: some View {
        WebViewScreen()
    }
} 
