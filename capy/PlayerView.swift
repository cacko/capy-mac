import AVFoundation
import SwiftUI

class PlayerView: NSView {

  var previewLayer: AVCaptureVideoPreviewLayer
  @ObservedObject var player = PlayerModel.instance

  init(
    captureSession: AVCaptureSession
  ) {
    previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    super.init(frame: .zero)
    setupLayer()
  }


  override public func mouseDown(with event: NSEvent) {
    if window!.inLiveResize {
      return
    }
    window?.performDrag(with: event)
  }

  func setupLayer() {
    previewLayer.frame = self.frame
    previewLayer.minificationFilter = .nearest
    previewLayer.magnificationFilter = .nearest
    previewLayer.videoGravity = .resizeAspect
    layer = previewLayer
  }

  required init?(
    coder: NSCoder
  ) {
    fatalError("init(coder:) has not been implemented")
  }
}

final class PlayerContainerView: NSViewRepresentable {
  typealias NSViewType = PlayerView

  let captureSession: AVCaptureSession

  init(
    captureSession: AVCaptureSession
  ) {
    self.captureSession = captureSession
  }

  func makeNSView(context: Context) -> PlayerView {
    return PlayerView(captureSession: captureSession)
  }

  func updateNSView(_ nsView: PlayerView, context: Context) {}
}
