//
//  ContentView.swift
//  capy
//
//  Created by Alex on 28/08/2021.
//

import SwiftUI
import AVFoundation


struct ContentView: View {
    @ObservedObject var player = PlayerModel()

    init() {
        player.checkAuthorization()
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                PlayerContainerView(captureSession: player.captureSession)
                .aspectRatio(16/9, contentMode: ContentMode.fit)
                .frame(width: geo.size.width, height: geo.size.height)
                .border(.bar, width: player.borderWidth)
                 .scaledToFill()
                 .fixedSize()
            }
            Text(player.error)
        }
        .frame(minWidth: 300, maxWidth: 1920, minHeight: 167, maxHeight: 1080, alignment: .center)
            .cornerRadius(player.cornerRadius)
    }
}
