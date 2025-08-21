import SwiftUI

struct ContentView: View {
    @State private var animationOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var hasError = false
    @State private var errorMessage = ""
    
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
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                abstractBackgroundElements
                
                VStack(spacing: 60) {
                    VStack(spacing: 20) {
                        Text("JLR")
                            .font(.system(size: 48, weight: .ultraLight, design: .default))
                            .foregroundColor(.black)
                        
                        Text("MT Client")
                            .font(.system(size: 48, weight: .thin, design: .default))
                            .foregroundColor(.gray)
                        
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 120, height: 1)
                            .scaleEffect(x: pulseScale, anchor: .center)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseScale)
                    }
                    
                    VStack(spacing: 30) {
                        navigationCard(
                            destination: TestFormView(),
                            icon: "doc.text",
                            title: "Event Log",
                            subtitle: "Monitoring and Recording",
                            delay: 0.1
                        )
                        
                        navigationCard(
                            destination: DrivingRecordsView(),
                            icon: "list.bullet.clipboard",
                            title: "History Event",
                            subtitle: "Audio Transcripts with Coordinates",
                            delay: 0.2
                        )
                        
                        navigationCard(
                            destination: WebBrowserView(),
                            icon: "globe",
                            title: "MT Manager",
                            subtitle: "Embedded Dashboard",
                            delay: 0.4
                        )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.top, 60)
            }
            .navigationBarHidden(true)
        }
    }
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Text("Error View")
                .font(.title)
                .foregroundColor(.red)
            
            Text(errorMessage)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
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
            HStack(spacing: 20) {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.05))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Rectangle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .ultraLight))
                        .foregroundColor(.black)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .ultraLight))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .ultraLight))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 25)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
            )
            .opacity(1.0)
        }
        .buttonStyle(PlainButtonStyle())
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
}
