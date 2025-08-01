//
//  ContentView.swift
//  JRLTest
//
//  Created by whosyihan on 7/25/25.
//

import SwiftUI

struct ContentView: View {
    @State private var animationOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background with subtle gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.gray.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Abstract background shapes
                abstractBackgroundElements
                
                VStack(spacing: 60) {
                    // Header section
                    VStack(spacing: 20) {
                        Text("JRL")
                            .font(.system(size: 48, weight: .ultraLight, design: .default))
                            .foregroundColor(.black)
                        
                        Text("TEST")
                            .font(.system(size: 48, weight: .thin, design: .default))
                            .foregroundColor(.gray)
                        
                        // Animated line
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 120, height: 1)
                            .scaleEffect(x: pulseScale, anchor: .center)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseScale)
                    }
                    
                    // Navigation options
                    VStack(spacing: 30) {
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
                            destination: TestDashboardView(),
                            icon: "chart.bar",
                            title: "测试仪表板",
                            subtitle: "分析与统计",
                            delay: 0.3
                        )
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 40)
                .padding(.top, 60)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private var abstractBackgroundElements: some View {
        ZStack {
            // Floating geometric shapes
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
                // Icon container
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
        
        // Animate cards appearance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                // Card animations will be handled by individual cards
            }
        }
    }
}

#Preview {
    ContentView()
}
