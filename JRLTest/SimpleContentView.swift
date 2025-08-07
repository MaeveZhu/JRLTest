import SwiftUI

struct SimpleContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("JRL Test")
                .font(.largeTitle)
                .foregroundColor(.black)
            
            Text("简单测试版本")
                .font(.title2)
                .foregroundColor(.gray)
            
            Button("测试按钮") {
                print("按钮被点击")
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    SimpleContentView()
} 