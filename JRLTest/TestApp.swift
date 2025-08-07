import SwiftUI

struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            VStack(spacing: 20) {
                Text("JRL Test App")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                
                Text("测试版本 - 无 SiriKit")
                    .font(.title2)
                    .foregroundColor(.gray)
                
                Button("测试按钮") {
                    print("应用正常运行")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
        }
    }
} 