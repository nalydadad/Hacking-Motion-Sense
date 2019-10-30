//
//  MSCaptureManager.swift
//  Hacking Motion Sense
//
//  Created by DADA on 2019/10/29.
//  Copyright © 2019 nalydadad.com. All rights reserved.
//

import UIKit
import AVFoundation

protocol MSCaptureMangerDelegate: class {
	func captureManager(_ manager: MSCaptureManager, didOutput image: UIImage)
}

class MSCaptureManager: NSObject {
	private var session = AVCaptureSession()
	weak var delegate: MSCaptureMangerDelegate?
	private let dataOutputQueue = DispatchQueue(label: "MSCaptureSessionManager", attributes: [], autoreleaseFrequency: .workItem)
	
	func start() {
		configureCaptureSession()
		self.session.startRunning()
	}

	func stop() {
		session.stopRunning()
	}

	func configureCaptureSession() {
		guard let camera = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) else {
			fatalError("No depth video camera available")
		}
		session.sessionPreset = .vga640x480
		do {
			let cameraInput = try AVCaptureDeviceInput(device: camera)
			session.addInput(cameraInput)
		} catch {
			fatalError(error.localizedDescription)
		}

		let depthOutput = AVCaptureDepthDataOutput()
//		depthOutput.isFilteringEnabled = true
		depthOutput.setDelegate(self, callbackQueue: dataOutputQueue)
		session.addOutput(depthOutput)
		let depthConnection = depthOutput.connection(with: .depthData)
//		depthConnection?.isVideoMirrored = true
		depthConnection?.videoOrientation = .portrait

		do {
			try camera.lockForConfiguration()
			if let frameDuration = camera.activeDepthDataFormat?.videoSupportedFrameRateRanges.first?.minFrameDuration {
				camera.activeVideoMinFrameDuration = frameDuration
			}
			camera.unlockForConfiguration()
		}
		catch {
			fatalError(error.localizedDescription)
		}
		session.commitConfiguration()
	}
}

extension MSCaptureManager: AVCaptureDepthDataOutputDelegate {
	func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
		let convertedDepth: AVDepthData = depthData.depthDataType != kCVPixelFormatType_DepthFloat16 ?
											depthData.converting(toDepthDataType: kCVPixelFormatType_DepthFloat32) : depthData
		let pixelBuffer = convertedDepth.depthDataMap
		pixelBuffer.clamp()
		DispatchQueue.main.async {
			self.delegate?.captureManager(self, didOutput: UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer)))
		}
	}
}

extension CVPixelBuffer {
	func clamp() {
		let width = CVPixelBufferGetWidth(self)
		let height = CVPixelBufferGetHeight(self)
		CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
		let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float32>.self)
		for y in 0 ..< height {
			for x in 0 ..< width {
				var pixel = floatBuffer[y * width + x]
				pixel = pixel < 0.3 ? 1 : 0
				floatBuffer[y * width + x] = pixel
			}
		}
		CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
	}
}
