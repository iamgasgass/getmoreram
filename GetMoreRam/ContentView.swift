//
//  ContentView.swift
//  GetMoreRam
//
//  Created by s s on 2025/3/14.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0

    var body: some View {
        ZStack {
            AppGlassBackground()

            TabView(selection: $selection) {
                AppIDView(viewModel: AppIDViewModel())
                    .tabItem {
                        Label("App IDs".loc, systemImage: "square.stack.3d.up.fill")
                    }
                    .tag(0)

                SettingsView(viewModel: LoginViewModel())
                    .tabItem {
                        Label("Settings".loc, systemImage: "slider.horizontal.3")
                    }
                    .tag(1)
            }
            .tint(.white)
        }
        .preferredColorScheme(.dark)
        .environmentObject(DataManager.shared.model)
    }
}

#Preview {
    ContentView()
}
