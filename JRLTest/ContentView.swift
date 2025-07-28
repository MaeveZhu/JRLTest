//
//  ContentView.swift
//  JRLTest
//
//  Created by whosyihan on 7/25/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // 标题
                Text("JRL Test App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // 主要功能按钮
                VStack(spacing: 25) {
                    // 测试表单按钮
                    NavigationLink(destination: TestFormView()) {
                        VStack(spacing: 10) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 40))
                            Text("测试表单")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 300, height: 120)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    }
                    
                    // 语音录音按钮
                    NavigationLink(destination: VoiceRecordView()) {
                        VStack(spacing: 10) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 40))
                            Text("语音录音")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 300, height: 120)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    }
                    
                    // 网页浏览按钮
                    NavigationLink(destination: WebViewScreen()) {
                        VStack(spacing: 10) {
                            Image(systemName: "globe")
                                .font(.system(size: 40))
                            Text("网页浏览")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 300, height: 120)
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    }
                }
                
                Spacer()
                
                // 版本信息
                Text("Jaguar Land Rover Test App v1.0")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom)
            }
            .navigationTitle("JRLTest Home")
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
}
