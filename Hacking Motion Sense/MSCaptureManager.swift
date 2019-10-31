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
		depthOutput.isFilteringEnabled = true
		depthOutput.setDelegate(self, callbackQueue: dataOutputQueue)
		session.addOutput(depthOutput)
		let depthConnection = depthOutput.connection(with: .depthData)
		depthConnection?.isVideoMirrored = true
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
		let centerPoint = pixelBuffer.clamp()
		let image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
		let scale = CGFloat(CVPixelBufferGetWidth(pixelBuffer)) / CGFloat(image.size.width)
		DispatchQueue.main.async {
			
			UIGraphicsBeginImageContext(image.size)
			image.draw(at: .zero)
			let context = UIGraphicsGetCurrentContext()!
			context.setFillColor(UIColor.red.cgColor)
			context.fillEllipse(in: CGRect(x: centerPoint.x * scale - 10, y: centerPoint.y * scale - 10, width: 20, height: 20))
			let result = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			
			self.delegate?.captureManager(self, didOutput: result!)
		}
	}
}

extension CVPixelBuffer {
	func clamp() -> CGPoint {
		let width = CVPixelBufferGetWidth(self)
		let height = CVPixelBufferGetHeight(self)
		CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
		let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float32>.self)
		
		var amountX = 0
		var amountY = 0
		var amount = 0
		for y in 0 ..< height {
			for x in 0 ..< width {
				let index = y * width + x
				var pixel: Float32 = 0
				if floatBuffer[index] < 0.3 {
					amountX += x
					amountY += y
					amount += 1
					pixel = 1
				}
				floatBuffer[y * width + x] = pixel
			}
		}
		let avgX = amount != 0 ? Double(amountX) / Double(amount) : 0
		let avgY = amount != 0 ? Double(amountY) / Double(amount) : 0
		print("\(avgX), \(avgY)")
		CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
		return CGPoint(x: avgX, y: avgY)
	}
}
