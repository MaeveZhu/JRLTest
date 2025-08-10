import SwiftUI

struct ContentView: View {
    @State private var animationOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var hasError = false
    @State private var errorMessage = ""
    @EnvironmentObject var carPlayManager: CarPlayManager
    @State private var showingCarPlayTest = false
    @StateObject private var carPlayIntegration = CarPlayIntegrationManager.shared
    
    var body: some View {
        Group {
            if hasError {
                errorView
            } else {
                mainView
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private var mainView: some View {
        NavigationView {
            ZStack {
                // CarPlay-optimized background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color.gray.opacity(0.05),
                        Color.blue.opacity(0.02)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                abstractBackgroundElements
                
                VStack(spacing: carPlayManager.isCarPlayConnected ? 40 : 60) {
                    VStack(spacing: 20) {
                        Text("JRL")
                            .font(.system(size: carPlayManager.isCarPlayConnected ? 56 : 48, weight: .ultraLight, design: .default))
                            .foregroundColor(.black)
                        
                        Text("TEST")
                            .font(.system(size: carPlayManager.isCarPlayConnected ? 56 : 48, weight: .thin, design: .default))
                            .foregroundColor(.gray)
                        
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 120, height: 1)
                            .scaleEffect(x: pulseScale, anchor: .center)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseScale)
                    }
                    
                    // CarPlay status indicator
                    if carPlayManager.isCarPlayConnected {
                        HStack {
                            Image(systemName: "car.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                            Text("CarPlay Connected")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(20)
                    }
                    
                    VStack(spacing: carPlayManager.isCarPlayConnected ? 20 : 30) {
                        navigationCard(
                            destination: TestFormView(),
                            icon: "doc.text",
                            title: "开始测试",
                            subtitle: "新建测试会话",
                            delay: 0.1
                        )
                        
                        navigationCard(
                            destination: DrivingRecordsView(),
                            icon: "list.bullet.clipboard",
                            title: "行车记录", 
                            subtitle: "查看历史记录",
                            delay: 0.2
                        )
                        
                        navigationCard(
                            destination: WebBrowserView(),
                            icon: "globe",
                            title: "网页浏览器",
                            subtitle: "访问网站页面",
                            delay: 0.4
                        )
                        
                        // CarPlay-specific quick actions
                        if carPlayManager.isCarPlayConnected {
                            carPlayQuickActions
                        }

                        
                        // CarPlay test button
                        carPlayTestSection
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, carPlayManager.isCarPlayConnected ? 30 : 40)
                .padding(.top, carPlayManager.isCarPlayConnected ? 40 : 60)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCarPlayTest) {
            CarPlayTestView()
        }
    }
    
    private var carPlayQuickActions: some View {
        VStack(spacing: 15) {
            Text("CarPlay 快捷操作")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.blue)
            
            HStack(spacing: 20) {
                quickActionButton(
                    action: {
                        UnifiedAudioManager.shared.startRecordingWithCoordinate()
                    },
                    icon: "record.circle.fill",
                    title: "开始录音",
                    color: .red
                )
                
                quickActionButton(
                    action: {
                        if UnifiedAudioManager.shared.isRecording {
                            UnifiedAudioManager.shared.handleSiriStopCommand()
                        }
                    },
                    icon: "stop.circle.fill",
                    title: "停止录音",
                    color: .orange
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(15)
    }
    
    private func quickActionButton(
        action: @escaping () -> Void,
        icon: String,
        title: String,
        color: Color
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(width: 80, height: 80)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Text("应用启动错误")
                .font(.title)
                .foregroundColor(.red)
            
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("重试") {
                hasError = false
                errorMessage = ""
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
    
    private var abstractBackgroundElements: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.03))
                .frame(width: 200, height: 200)
                .offset(x: -150, y: -200)
                .scaleEffect(pulseScale * 0.8)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: pulseScale)
            
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.black.opacity(0.02))
                .frame(width: 100, height: 300)
                .rotationEffect(.degrees(15))
                .offset(x: 180, y: 100)
                .offset(x: animationOffset)
                .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animationOffset)
            
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                .frame(width: 150, height: 150)
                .offset(x: 100, y: -300)
                .rotationEffect(.degrees(animationOffset * 0.5))
                .animation(.linear(duration: 30).repeatForever(autoreverses: false), value: animationOffset)
        }
    }
    
    private func navigationCard<Destination: View>(
        destination: Destination,
        icon: String,
        title: String,
        subtitle: String,
        delay: Double
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: carPlayManager.isCarPlayConnected ? 25 : 20) {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.05))
                        .frame(width: carPlayManager.isCarPlayConnected ? 70 : 60, height: carPlayManager.isCarPlayConnected ? 70 : 60)
                        .overlay(
                            Rectangle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: carPlayManager.isCarPlayConnected ? 28 : 24, weight: .ultraLight))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: carPlayManager.isCarPlayConnected ? 20 : 18, weight: .light))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.system(size: carPlayManager.isCarPlayConnected ? 16 : 14, weight: .ultraLight))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: carPlayManager.isCarPlayConnected ? 18 : 16, weight: .ultraLight))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, carPlayManager.isCarPlayConnected ? 35 : 30)
            .padding(.vertical, carPlayManager.isCarPlayConnected ? 30 : 25)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
            .opacity(1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var carPlayIntegrationSection: some View {
        VStack(spacing: 15) {
            Text("CarPlay 集成状态")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.blue)
            
            HStack {
                Image(systemName: "car.fill")
                    .foregroundColor(.blue)
                Text("CarPlay 可用")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var carPlayTestSection: some View {
        VStack(spacing: 15) {
            Text("CarPlay 测试")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.orange)
            
            Button("测试 CarPlay 功能") {
                showingCarPlayTest = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 15)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(15)
    }
    
    private func startAnimations() {
        withAnimation {
            pulseScale = 1.2
        }
        
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            animationOffset = 50
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CarPlayManager.shared)
}
