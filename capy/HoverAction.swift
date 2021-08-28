//
//  HoverAction.swift
//  craptv
//
//  Created by Alex on 27/10/2021.
//

import Foundation
import SwiftUI

struct HoverAction: ViewModifier {

  enum Mode {
    case cursor, colors
  }

  @State var mode: [Mode] = [.cursor]

  let center = NotificationCenter.default
  let mainQueue = OperationQueue.main

  private let state: [() -> Void] = [
    { NSCursor.arrow.set() },
    { NSCursor.pointingHand.set() },
  ]

  private let bright: [Double] = [
    0.0,
    0.3,
  ]

  @State private var brightness: Double = 0.0

  @State var isHovered: Bool = false {
    didSet {
      if self.mode.contains(.cursor) {
        state[isHovered.intValue]()
      }
      if self.mode.contains(.colors) {
        self.brightness = self.bright[isHovered.intValue]
      }
    }
  }

  func body(content: Content) -> some View {
    content
      .onHover(perform: { _ in isHovered.toggle() })
      .brightness(brightness)
  }
}

extension View {

  func hoverAction(mode: [HoverAction.Mode]? = nil) -> some View {
    modifier(
      HoverAction(mode: mode ?? [.cursor])
    )
  }

}
