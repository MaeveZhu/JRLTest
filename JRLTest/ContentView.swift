//
//  ContentView.swift
//  JRLTest
//
//  Created by whosyihan on 7/25/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Text("...")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 20) {
                    NavigationLink(destination: SimpleVoiceRecordView()) {
                        VStack(spacing: 10) {
                            Image(systemName: "mic.circle.fill")
                                .font(.system(size: 50))
                            Text("语音录音")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 300, height: 200)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    
                    NavigationLink(destination: SimpleTestRecordingView()) {
                        VStack(spacing: 10) {
                            Image(systemName: "mic.circle")
                                .font(.system(size: 50))
                            Text("录音测试")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 300, height: 200)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    
                    NavigationLink(destination: TestFormView()) {
                        VStack(spacing: 10) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 50))
                            Text("测试表单")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        .frame(width: 300, height: 200)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("JRLTest Home")
        }
    }
}

#Preview {
    ContentView()
}
