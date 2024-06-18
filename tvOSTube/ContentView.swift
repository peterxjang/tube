//
//  ContentView.swift
//  tvOSTube
//
//  Created by Peter Jang on 6/14/24.
//

import SwiftUI

struct ContentView: View {
    
    @State private var text = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            TextField("Invidious Instance", text: $text)
                .keyboardType(.URL)
                .focused($isTextFieldFocused) // This binds the focus state to our property
                //.textFieldStyle(RoundedBorderTextFieldStyle()) // Optional: for better visualization
                .padding()
        }
        .padding()
        .onAppear {
            // Automatically focus the text field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

#Preview {
    ContentView()
        .previewDevice("Apple TV") // Ensuring the preview environment is set to tvOS
}
