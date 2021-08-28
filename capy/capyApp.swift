//
//  capyApp.swift
//  capy
//
//  Created by Alex on 28/08/2021.
//

import SwiftUI
import AppKit
import AVFoundation

@main
struct capyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
        }
    }
}

class MainWindowController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        super.windowDidLoad()

        self.window?.delegate = self

    }
    
}

extension NSWindow.StyleMask {
    static var defaultWindow: NSWindow.StyleMask {
        var styleMask: NSWindow.StyleMask = .closable
        styleMask.formUnion(.fullSizeContentView)
        styleMask.formUnion(.resizable)
        return styleMask
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
            
    let windowController = MainWindowController(
         window: NSWindow(contentRect: NSMakeRect(100, 100, NSScreen.main!.frame.width/2, NSScreen.main!.frame.height/2),
                          styleMask: .defaultWindow,
                          backing: .buffered,
        defer: false))
    
    let _rootView = ContentView()

    var fixedRaio = NSSize(width: 1920, height: 1080)
    
    
    @objc func didSelectDevices() {
        print("this will never be called")
    }

    @objc func didSelectDevice(sender: NSMenuItem) {
        switch sender.menu?.title {
        case "Audio":
            _rootView.player.onAudioDeviceChange(sender.title)
            break
            
        case "Video":
            _rootView.player.onVideoDeviceChange(sender.title)
            break
            
        default:
            break;
        }
    }
    
    
    func addMenus(_title: String, _devices: Array<AVCaptureDevice>, on: String) {
        guard let mainMenu = NSApp.mainMenu else {
            return
        }
        mainMenu.autoenablesItems = true
        let menuItem = mainMenu.addItem(withTitle: _title, action: #selector(didSelectDevices), keyEquivalent: "")
        
        menuItem.target = self
        
        let submenu = NSMenu(title: _title)
        menuItem.submenu = submenu
        
        for device in _devices {
            let deviceItem = submenu.addItem(withTitle: device.localizedName, action: #selector(didSelectDevice), keyEquivalent: "")
            deviceItem.target = self
            if device.localizedName == on {
                deviceItem.state = .on
            }
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        
        let app:NSApplication = notification.object as! NSApplication
        let crapwindow = app.windows.first
            crapwindow?.setIsVisible(false)
        
        let mainMenu = app.mainMenu
        
        let _ = mainMenu!.items.filter { !["capy", "Help"].contains($0.title) }.map{ $0.menu?.removeItem($0) }
                        
        addMenus(_title: "Video", _devices:  _rootView.player.videoDevices(), on: _rootView.player._videoInput)
        addMenus(_title: "Audio", _devices: _rootView.player.audioDevices(), on: _rootView.player._audioInput)

        let contentViewController = NSHostingController(rootView: _rootView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 360),
            styleMask: [.closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.level = .floating
        window.contentView = contentViewController.view
        window.makeKeyAndOrderFront(nil)
        window.contentAspectRatio = fixedRaio
        window.collectionBehavior = .fullScreenPrimary
        window.backgroundColor = .clear
        window.showsResizeIndicator = true
        window.hasShadow = false
        windowController.window?.delegate = windowController
        if _rootView.player.error != "" {
            window.setContentSize(NSSize(width: 640, height: 360))
            window.backgroundColor = .red
        }
        windowController.showWindow(self)
        
        var isFloating = true {
            didSet {
                window.level = isFloating ? .floating : .normal
                _rootView.player.borderWidth = isFloating ? 0 : 5
                _rootView.player.cornerRadius = isFloating ? 5 : 10
            }
        }
        
        NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { (theEvent) -> NSEvent? in
            switch theEvent.characters {
                    case "a":
                      isFloating.toggle();
                      break
                    case "f":
                         window.toggleFullScreen(self)
                      break;
                  default:
                if 0x35 == theEvent.keyCode && ((window.contentView?.isInFullScreenMode) != nil) {
                    window.toggleFullScreen(self)
                }
                break
            }
            return theEvent
        }
    }
    
}


