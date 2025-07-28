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
                NavigationLink(destination: VoiceRecordView()) {
                    Text("Talk")
                        .font(.largeTitle)
                        .frame(width: 300, height: 300)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                NavigationLink(destination: WebViewScreen()) {
                    Text("Web")
                        .font(.largeTitle)
                        .frame(width: 300, height:300)
                        .background(Color.pink)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("JRLTest Home")
        }
    }
}

#Preview {
    ContentView()
}
