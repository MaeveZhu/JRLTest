import SwiftUI
import WebKit

struct WebBrowserView: View {
    @State private var ipAddress = ""
    @State private var isLoading = false
    @State private var connectionStatus = "准备连接"
    @State private var useHTTPS = false
    @State private var currentURL = ""
    @Environment(\.dismiss) private var dismiss
    
    private let serverPort = "5063"
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Connection status bar
                HStack {
                    Image(systemName: isLoading ? "antenna.radiowaves.left.and.right" : "network")
                        .foregroundColor(isLoading ? .orange : .blue)
                    Text(connectionStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                
                // IP address input section
                VStack(spacing: 12) {
                    Text("服务器连接")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    VStack(spacing: 8) {
                        HStack {
                            TextField("输入IP地址 (例: 192.168.1.100)", text: $ipAddress)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .keyboardType(.numbersAndPunctuation)
                                .onSubmit {
                                    connectToServer()
                                }
                            
                            Button("连接") {
                                connectToServer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(ipAddress.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .disabled(ipAddress.isEmpty)
                        }
                        
                        HStack {
                            Text("端口: \(serverPort) (HTTP)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Toggle("HTTPS", isOn: $useHTTPS)
                                .font(.caption)
                                .foregroundColor(useHTTPS ? .orange : .green)
                        }
                        
                        // Current URL display
                        if !currentURL.isEmpty {
                            Text("连接URL: \(currentURL)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                        }
                        
                        // Common IP examples
                        HStack {
                            Text("常用格式: ")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button("192.168.1.x") { 
                                ipAddress = "192.168.1."
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                            
                            Button("192.168.0.x") { 
                                ipAddress = "192.168.0."
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(4)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                
                // Web content
                ZStack {
                    if isLoading {
                        VStack {
                            ProgressView()
                            Text("正在连接 \(currentURL)")
                                .padding(.top, 8)
                                .font(.caption)
                        }
                    } else if ipAddress.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "globe")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("请输入服务器IP地址")
                                .font(.headline)
                                .foregroundColor(.gray)
                            VStack(spacing: 4) {
                                Text("1. 输入您的服务器IP地址")
                                Text("2. 确保使用HTTP协议（推荐）")
                                Text("3. 点击'连接'访问端口 \(serverPort)")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text("大多数本地服务器使用HTTP协议")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                    } else {
                        WebView(
                            urlString: currentURL, 
                            isLoading: $isLoading, 
                            onError: { error in
                                connectionStatus = "连接失败: \(error)"
                            },
                            onStatusChange: { status in
                                connectionStatus = status
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("网页浏览器")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("刷新") {
                        if !ipAddress.isEmpty {
                            connectToServer()
                        }
                    }
                    .disabled(ipAddress.isEmpty)
                }
            }
        }
    }
    
    private func buildURL() -> String {
        guard !ipAddress.isEmpty else { return "" }
        let cleanIP = ipAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        let urlProtocol = useHTTPS ? "https" : "http"
        return "\(urlProtocol)://\(cleanIP):\(serverPort)"
    }
    
    private func connectToServer() {
        guard !ipAddress.isEmpty else { return }
        connectionStatus = "正在连接..."
        currentURL = buildURL()
    }
}

// MARK: - WebView (Enhanced with better error handling)
struct WebView: UIViewRepresentable {
    let urlString: String
    @Binding var isLoading: Bool
    let onError: (String) -> Void
    let onStatusChange: (String) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // Allow local network connections
        webView.configuration.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if !urlString.isEmpty, let url = URL(string: urlString), webView.url != url {
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            request.timeoutInterval = 15.0
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                self.parent.onStatusChange("正在连接...")
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.onStatusChange("连接成功")
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.onError("导航失败: \(error.localizedDescription)")
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                let errorMsg = error.localizedDescription
                
                if errorMsg.contains("not connected to the internet") {
                    self.parent.onError("网络连接失败，请检查IP地址和网络")
                } else if errorMsg.contains("could not connect to the server") {
                    self.parent.onError("无法连接服务器，请确认服务器正在运行")
                } else if errorMsg.contains("unsupported URL") {
                    self.parent.onError("URL格式错误，请检查IP地址")
                } else if errorMsg.contains("The request timed out") {
                    self.parent.onError("连接超时，请检查IP地址和服务器状态")
                } else if errorMsg.contains("SSL") || errorMsg.contains("certificate") {
                    self.parent.onError("SSL证书错误，请关闭HTTPS开关")
                } else {
                    self.parent.onError("连接失败: \(errorMsg)")
                }
                
                // Suggest checking server
                self.parent.onStatusChange("连接失败，请确认服务器正在运行")
            }
        }
    }
}

#Preview {
    WebBrowserView()
}
