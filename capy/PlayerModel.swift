//
//  PlayerModel.swift
//  PlayerModel
//
//  Created by Alex on 31/08/2021.
//

import AVFoundation
import AppKit
import Combine
import SwiftUI

struct DeviceError: Error, Identifiable {
  var id: Errors

  enum Errors {
    case deviceLoad
    case accessDenied
    case unexpected
  }

  //    let kind: Errors
  let msg: String
}

class PlayerModel: ObservableObject {

  @Published var isGranted: Bool = false
  @Published var borderWidth: CGFloat = 0
  @Published var error: DeviceError? = nil
  @Published var cornerRadius: CGFloat = 0
  @Published var muted: Bool = false
  @Published var resolution: CGSize = CGSize(width: 1920, height: 1080)
  @Published var onTop: Bool = true

  static let instance: PlayerModel = { PlayerModel() }()

  var _audioInput: String = UserDefaults.standard.string(forKey: "AudioInput") ?? ""
  var _videoInput: String = UserDefaults.standard.string(forKey: "VideoInput") ?? ""
  var videoDevice: AVCaptureDevice? = nil
  var audioDevice: AVCaptureDevice? = nil
  var audioOutput: AVCaptureAudioPreviewOutput? = nil

  var captureSession: AVCaptureSession!
  private var cancellables = Set<AnyCancellable>()

  init() {
    captureSession = AVCaptureSession()
    setupBindings()
  }

  func setupBindings() {
    $isGranted
      .sink { [weak self] isGranted in
        isGranted ? self?.prepareCamera() : self?.stopSession()
      }.store(in: &cancellables)
  }

  func checkAuthorization() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:  // The user has previously granted access to the camera.
      self.isGranted = true

    case .notDetermined:  // The user has not yet been asked for camera access.
      AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
        if granted {
          DispatchQueue.main.async {
            self?.isGranted = granted
          }
        }
      }

    case .denied:  // The user has previously denied access.
      self.isGranted = false
      self.error = DeviceError(id: .accessDenied, msg: "Access is denied")
      return

    case .restricted:  // The user can't grant access due to restrictions.
      self.isGranted = false
      self.error = DeviceError(id: .accessDenied, msg: "Access is restricted")
      return
    @unknown default:
      fatalError()
    }
  }

  func startSession() {
    guard !captureSession.isRunning else { return }
    captureSession.startRunning()
  }

  func stopSession() {
    guard captureSession.isRunning else { return }
    for input in captureSession.inputs { captureSession.removeInput(input) }
    captureSession.stopRunning()
  }

  func muteAudio(mode: Bool) {
    audioOutput?.volume = mode ? 0 : 1
    muted = mode
  }

  func videoDevices() -> [AVCaptureDevice] {
    AVCaptureDevice
      .DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
        mediaType: .video,
        position: .unspecified
      ).devices
  }

  func audioDevices() -> [AVCaptureDevice] {
    AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInMicrophone],
      mediaType: .audio,
      position: .unspecified
    ).devices
  }

  func prepareCamera() {
    do {

      guard
        let _video = findDevice(
          _name: _videoInput,
          _devices: videoDevices(),
          _default: _videoInput == "" ? .video : nil
        )
      else {
        throw DeviceError(id: .deviceLoad, msg: "Video input not available")
      }
      videoDevice = _video
      guard
        let _audio = findDevice(
          _name: _audioInput,
          _devices: audioDevices(),
          _default: _audioInput == "" ? .audio : nil
        )
      else {
        throw DeviceError(id: .deviceLoad, msg: "Audio input not available")
      }
      audioDevice = _audio
      self.error = nil
      startSessionForDevice()
    }
    catch let e as DeviceError {
      self.error = e

    }
    catch {
      self.error = DeviceError(id: .unexpected, msg: "Alabala")

    }
  }

  func findDevice(
    _name: String,
    _devices: [AVCaptureDevice],
    _default: AVMediaType? = nil
  ) -> AVCaptureDevice? {
    _devices.first(where: { device in device.localizedName == _name })
      ?? AVCaptureDevice.default(for: _default ?? AVMediaType(rawValue: ""))
  }

  func onVideoDeviceChange(_ video: String) {
    guard let _video = findDevice(_name: video, _devices: videoDevices()) else {
      return
    }

    videoDevice = _video

    NSApplication.shared.mainMenu?.item(withTitle: "Video")?.submenu?.item(withTitle: _videoInput)?
      .state = .off

    guard let _audio = findDevice(_name: _audioInput, _devices: audioDevices()) else {
      return
    }

    audioDevice = _audio

    stopSession()

    startSessionForDevice()

  }

  func onAudioDeviceChange(_ audio: String) {
    guard let _audio = audioDevices().first(where: { device in device.localizedName == audio })
    else {
      return
    }

    audioDevice = _audio

    NSApplication.shared.mainMenu?.item(withTitle: "Audio")?.submenu?.item(withTitle: _audioInput)?
      .state = .off

    stopSession()

    guard let _video = findDevice(_name: _videoInput, _devices: videoDevices()) else {
      return
    }

    videoDevice = _video

    startSessionForDevice()

  }

  func getResolution(_ device: AVCaptureDevice) -> CGSize {
    let bestFormat: AVCaptureDevice.Format? = device.formats.max(by: {
      (s1: AVCaptureDevice.Format, s2: AVCaptureDevice.Format) -> Bool in
      return
        CMVideoFormatDescriptionGetDimensions(s1.formatDescription).width
        < CMVideoFormatDescriptionGetDimensions(s2.formatDescription).width
    })

    let dimensions = CMVideoFormatDescriptionGetDimensions(bestFormat!.formatDescription)
    return CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height))
  }

  private func getPreset() -> AVCaptureSession.Preset {
    if CGSize(width: 1920, height: 1080).equalTo(resolution) {
      return AVCaptureSession.Preset.hd1920x1080
    }
    return AVCaptureSession.Preset.high
  }

  private func startSessionForDevice() {
    do {
      try videoDevice!.lockForConfiguration()
      captureSession.beginConfiguration()
      resolution = getResolution(videoDevice!)
      captureSession.sessionPreset = getPreset()
      let input = try AVCaptureDeviceInput(device: videoDevice!)
      _videoInput = videoDevice!.localizedName
      NSApplication.shared.mainMenu?.item(withTitle: "Video")?.submenu?.item(
        withTitle: _videoInput
      )?.state = .on
      UserDefaults.standard.set(_videoInput, forKey: "VideoInput")
      let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
      _audioInput = audioDevice!.localizedName
      UserDefaults.standard.set(_videoInput, forKey: "AudioInput")
      NSApplication.shared.mainMenu?.item(withTitle: "Audio")?.submenu?.item(
        withTitle: _audioInput
      )?.state = .on
      audioOutput = AVCaptureAudioPreviewOutput()
      audioOutput?.volume = 1
      addInput(input)
      addInput(audioInput)
      addOuput(audioOutput!)
      captureSession.commitConfiguration()
      videoDevice!.unlockForConfiguration()
      self.error = nil
      startSession()
      NotificationCenter.default.post(name: .onResolutionChange, object: nil)
    }
    catch {
      print("Something went wrong - ", error.localizedDescription)
    }
  }

  func addInput(_ input: AVCaptureInput) {
    guard captureSession.canAddInput(input) == true else {
      return
    }
    captureSession.addInput(input)
  }

  func addOuput(_ output: AVCaptureOutput) {
    guard captureSession.canAddOutput(output) == true else {
      return
    }
    captureSession.addOutput(output)
  }

  @objc func deviceAction() {
    NSApplication.shared.activate(ignoringOtherApps: true)
  }
}
