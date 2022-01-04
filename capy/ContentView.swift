//
//  ContentView.swift
//  capy
//
//  Created by Alex on 28/08/2021.
//

import AVFoundation
import SwiftUI

struct ContentView: View {
  @ObservedObject var player = PlayerModel.instance

  init() {
    player.checkAuthorization()
  }

  func onToggleOnTop() {
    NotificationCenter.default.post(name: .toggleOnTop, object: nil)
  }

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      GeometryReader { geo in
        PlayerContainerView(captureSession: player.captureSession)
          .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
          .aspectRatio(player.resolution, contentMode: .fit)
          .background(.clear)
          .padding(geo.safeAreaInsets)
      }
      HStack {
        Image(systemName: "speaker.slash")
          .font(.title)
          .padding()
          .foregroundColor(.white)
          .opacity(player.muted ? 0.8 : 0)
        Spacer()
        Button(action: { onToggleOnTop() }) {
          Image(systemName: player.onTop ? "square.stack.3d.up.fill" : "square.stack.3d.up.slash")
            .symbolRenderingMode(.hierarchical)
            .font(.title)
            .padding()
            .foregroundColor(.white)
            .opacity(0.5)
        }.buttonStyle(.borderless).help("Toggle on top behaviour").hoverAction(mode: [.cursor])
      }
    }.alert(item: $player.error) { err in
      Alert(title: Text("Device error"), message: Text(err.msg), dismissButton: .cancel())
    }
    .aspectRatio(player.resolution, contentMode: .fill)
    .background(.black)
  }
}
