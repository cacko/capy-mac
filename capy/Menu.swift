//
//  Menu.swift
//  Menu
//
//  Created by Alex on 01/09/2021.
//

import AVFoundation
import AppKit
import Foundation
import IOKit
import IOKit.pwr_mgt
import SwiftUI

extension Notification.Name {
  static let toggleOnTop = NSNotification.Name("toggle_ontop")
  static let onResolutionChange = NSNotification.Name("resolution.change")
}

class CrapItem: NSMenuItem, NSUserInterfaceValidations {
  func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    return true
  }
}

class AudioMenu: CrapMenu {
  override var devices: [AVCaptureDevice] { PlayerModel.instance.audioDevices() }
  override var onDevice: String { PlayerModel.instance._audioInput }

  override var actions: [NSMenuItem] {
    [
      NSMenuItem(title: "Toggle sound", action: #selector(onAudioMute(sender:)), keyEquivalent: "m")
    ]
  }

  override func didSelectDevice(sender: NSMenuItem) {
    PlayerModel.instance.onAudioDeviceChange(sender.title)
  }
}

class VideoMenu: CrapMenu {

  override var devices: [AVCaptureDevice] { PlayerModel.instance.videoDevices() }

  override var onDevice: String { PlayerModel.instance._audioInput }

  override var actions: [NSMenuItem] {
    [
      NSMenuItem(
        title: "Always on top",
        action: #selector(onAlwaysOnTop(sender:)),
        keyEquivalent: "a"
      ),
      NSMenuItem(
        title: "Toggle full screen",
        action: #selector(onToggleFullscreen(sender:)),
        keyEquivalent: "f"
      ),
      NSMenuItem(
        title: "Minimize",
        action: #selector(onMinimize(sender:)),
        keyEquivalent: "\u{1b}"
      ),
    ]
  }

  override func didSelectDevice(sender: NSMenuItem) {
    PlayerModel.instance.onVideoDeviceChange(sender.title)
  }
}

class CrapMenu: NSMenu {

  var devices: [AVCaptureDevice] {
    return []
  }
  var actions: [NSMenuItem] {
    return []
  }

  var onDevice: String {
    return ""
  }

  var parent: Menu

  init(
    _ _title: String,
    _ _parent: Menu
  ) {
    parent = _parent
    super.init(title: _title)
    _init()
  }

  func _init() {
    for device in devices {
      let deviceItem = CrapItem()
      deviceItem.title = device.localizedName
      deviceItem.action = #selector(didSelectDevice(sender:))
      deviceItem.target = self
      self.addItem(deviceItem)
      deviceItem.state = device.localizedName == onDevice ? .on : .off
    }

    guard actions.count == 0 else {
      self.addItem(NSMenuItem.separator())
      for item in actions {
        item.keyEquivalentModifierMask.remove(.command)
        item.target = self
        self.addItem(item)
      }
      return

    }
  }

  required init(
    coder: NSCoder
  ) {
    fatalError("init(coder:) has not been implemented")
  }

  @objc func onToggleFullscreen(sender: NSMenuItem) {
    parent.isFullScreen.toggle()
    sender.state = parent.isFullScreen ? .on : .off
  }

  @objc func onAudioMute(sender: NSMenuItem) {
    parent.isMuted.toggle()
    sender.state = parent.isMuted ? .on : .off
  }

  @objc func onAlwaysOnTop(sender: NSMenuItem) {
    parent.isFloating.toggle()
    sender.state = parent.isFloating ? .on : .off
  }

  @objc func onQuit(sender: NSMenuItem) {
    NSApplication.shared.terminate(sender)
  }

  @objc func didSelectDevices(_ sender: NSMenuItem) {
    print("this will never be called")
  }

  @objc func onMinimize(sender: NSMenuItem) {
    if parent.isFullScreen {
      return parent.isFullScreen.toggle()
    }
    parent.window.miniaturize(self)
  }

  @objc func didSelectDevice(sender: NSMenuItem) {

  }

}

class Menu: NSMenu, NSMenuDelegate, NSMenuItemValidation, NSUserInterfaceValidations {
  func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
    return true
  }

  func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    return true
  }

  let player: PlayerModel = PlayerModel.instance
  var window: NSWindow
  var mainMenu: NSMenu

  var noSleepAssertionID: IOPMAssertionID = 0
  var noSleepReturn: IOReturn?

  func disableScreenSleep(reason: String = "Unknown reason") -> Bool? {
    guard noSleepReturn == nil else { return nil }
    noSleepReturn = IOPMAssertionCreateWithName(
      kIOPMAssertionTypeNoDisplaySleep as CFString,
      IOPMAssertionLevel(kIOPMAssertionLevelOn),
      reason as CFString,
      &noSleepAssertionID
    )
    return noSleepReturn == kIOReturnSuccess
  }

  func enableScreenSleep() -> Bool {
    if noSleepReturn != nil {
      _ = IOPMAssertionRelease(noSleepAssertionID) == kIOReturnSuccess
      noSleepReturn = nil
      return true
    }
    return false
  }

  var isFloating = false {
    didSet {
      guard isFullScreen else {
        window.level = isFloating ? .floating : .normal
        _ = isFloating ? disableScreenSleep() : enableScreenSleep()
        PlayerModel.instance.onTop = isFloating
        return
      }
    }
  }

  var isFullScreen = false {
    didSet {
      window.toggleFullScreen(self)
      if isFullScreen {
        NSCursor.hide()
        let _ = disableScreenSleep()
        isFloating = isFullScreen
      }
      else {
        let _ = enableScreenSleep()
        NSCursor.unhide()
      }
    }
  }

  var isMuted = false {
    didSet {
      PlayerModel.instance.muteAudio(mode: isMuted)
    }
  }

  init(
    _ _window: NSWindow
  ) {
    window = _window
    mainMenu = NSApplication.shared.mainMenu ?? NSMenu()
    super.init(title: "")
    self._init()
    self.update()
    let center = NotificationCenter.default
    let mainQueue = OperationQueue.main
    
    center.addObserver(forName: .toggleOnTop ,  object: nil, queue: mainQueue) { _ in
      self.isFloating.toggle()
    }
    
    center.addObserver(forName: .onResolutionChange, object: nil, queue: mainQueue) { _ in
      self.window.aspectRatio = self.player.resoluion
      self.window.contentAspectRatio = self.player.resoluion
    }
    self.window.aspectRatio = self.player.resoluion
    self.window.contentAspectRatio = self.player.resoluion

  }

  required init(
    coder: NSCoder
  ) {
    fatalError("init(coder:) has not been implemented")
  }

  override func addItem(_ newItem: NSMenuItem) {
    mainMenu.addItem(newItem)
  }

  override func addItem(
    withTitle string: String,
    action selector: Selector?,
    keyEquivalent charCode: String
  ) -> NSMenuItem {
    return mainMenu.addItem(withTitle: string, action: selector, keyEquivalent: charCode)
  }

  func _init() {
    _ = mainMenu.items.dropFirst().map { $0.menu?.removeItem($0) }
    mainMenu.delegate = self
    addMenu(VideoMenu("Video", self))
    addMenu(AudioMenu("Audio", self))
  }

  func addMenu(_ menu: CrapMenu) {
    let menuItem = addItem(withTitle: menu.title, action: nil, keyEquivalent: "")
    menuItem.target = self
    menu.delegate = self
    menuItem.submenu = menu
  }
}
