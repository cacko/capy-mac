//
//  capyApp.swift
//  capy
//
//  Created by Alex on 28/08/2021.
//

import AVFoundation
import AppKit
import Combine
import SwiftUI

extension Bool {
  var intValue: Int {
    return self ? 1 : 0
  }
}

@main
struct capyApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

class MainWindowController: NSWindowController, NSWindowDelegate {
  override func windowDidLoad() {
    super.windowDidLoad()
    self.window?.delegate = self
  }
}

class AppDelegate: NSObject, NSApplicationDelegate {

  func applicationDidFinishLaunching(_ notification: Notification) {

    let app: NSApplication = notification.object as! NSApplication
    guard let window = app.windows.first else {
      return
    }
    let menu = Menu(window)
    window.center()
    window.setFrameAutosaveName("Main Window")
    window.makeKeyAndOrderFront(nil)
    window.collectionBehavior = .fullScreenPrimary
    menu.isFloating.toggle()
  }
}
