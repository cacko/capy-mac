//
//  PlayerModel.swift
//  PlayerModel
//
//  Created by Alex on 31/08/2021.
//

import AVFoundation
import Combine
import AppKit
import SwiftUI

class PlayerModel: ObservableObject {

    @Published var isGranted: Bool = false
    @Published var error: String = ""
    @Published var borderWidth: CGFloat = 0
    @Published var cornerRadius: CGFloat = 5

    
    var _audioInput: String = UserDefaults.standard.string(forKey: "AudioInput") ?? ""
    var _videoInput: String = UserDefaults.standard.string(forKey: "VideoInput") ?? ""
    
    var captureSession: AVCaptureSession!
    private var cancellables = Set<AnyCancellable>()

    init() {
        captureSession = AVCaptureSession()
        setupBindings()
    }

    func setupBindings() {
        $isGranted
            .sink { [weak self] isGranted in
                if isGranted {
                    self?.prepareCamera()
                } else {
                    self?.stopSession()
                }
            }
            .store(in: &cancellables)
    }

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                self.isGranted = true

            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                    if granted {
                        DispatchQueue.main.async {
                            self?.isGranted = granted
                        }
                    }
                }

            case .denied: // The user has previously denied access.
                self.isGranted = false
                self.error = "Access is denied"
                return

            case .restricted: // The user can't grant access due to restrictions.
                self.isGranted = false
                self.error = "Access is restricted"
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
        for input in captureSession.inputs { captureSession.removeInput(input)}
        captureSession.stopRunning()
    }
    
    func videoDevices() -> Array<AVCaptureDevice> {
        captureSession.sessionPreset = .high
        let discoverySession = AVCaptureDevice
            .DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .externalUnknown], mediaType: .video, position: .unspecified)
        return discoverySession.devices
    }
    
    func audioDevices() -> Array<AVCaptureDevice> {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes:[.builtInMicrophone],
            mediaType: .audio, position: .unspecified)
        return discoverySession.devices
    }

    func prepareCamera() {
        if let _video = findDevice(_name: _videoInput, _devices: videoDevices(), _default: .video) {
            if let _audio = findDevice(_name: _audioInput, _devices: audioDevices(), _default: .audio) {
                startSessionForDevice(video: _video, audio: _audio)
            } else {
                self.error = "NOT VIDEO INPUT SELECTED"
            }
        } else {
            self.error = "NOT VIDEO INPUT SELECTED"
        }
    }
    
    func findDevice(_name: String, _devices: Array<AVCaptureDevice>, _default: AVMediaType = .video) -> AVCaptureDevice? {
        if _name == "" {
            return AVCaptureDevice.default(for: _default)
        }
        return _devices.first(where: {device in device.localizedName == _name})
    }
    
    func onVideoDeviceChange(_ video : String) {
        guard let _video = findDevice(_name: video, _devices: videoDevices()) else {
            return
        }
        
        NSApplication.shared.mainMenu?.item(withTitle: "Video")?.submenu?.item(withTitle: _videoInput)?.state = .off

        
        guard let _audio = findDevice(_name: _audioInput, _devices: audioDevices()) else {
            return
        }
                
        stopSession()

        startSessionForDevice(video: _video, audio: _audio)
     
    }
    
    func onAudioDeviceChange(_ audio: String) {
        guard let _audio = audioDevices().first(where: {device in device.localizedName == audio}) else {
            return
        }
        
        NSApplication.shared.mainMenu?.item(withTitle: "Audio")?.submenu?.item(withTitle: _audioInput)?.state = .off
        
        stopSession()
        
        guard let _video = findDevice(_name: _videoInput, _devices: videoDevices()) else {
            return
        }
        
        startSessionForDevice(video: _video, audio: _audio)
        
    }

    func startSessionForDevice(video: AVCaptureDevice, audio: AVCaptureDevice) {
        do {
            let input = try AVCaptureDeviceInput(device: video)
            _videoInput = video.localizedName
            NSApplication.shared.mainMenu?.item(withTitle: "Video")?.submenu?.item(withTitle: _videoInput)?.state = .on
            UserDefaults.standard.set(_videoInput, forKey: "VideoInput")
            let audioInput = try AVCaptureDeviceInput(device: audio)
            _audioInput = audio.localizedName
            UserDefaults.standard.set(_videoInput, forKey: "AudioInput")
            NSApplication.shared.mainMenu?.item(withTitle: "Audio")?.submenu?.item(withTitle: _audioInput)?.state = .on
            let audioOutput = AVCaptureAudioPreviewOutput()
            audioOutput.volume = 1
            addInput(input)
            addInput(audioInput)
            addOuput(audioOutput)
            startSession()
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

