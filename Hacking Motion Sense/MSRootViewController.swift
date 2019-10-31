//
//  MSRootViewController.swift
//  Hacking Motion Sense
//
//  Created by DADA on 2019/10/29.
//  Copyright © 2019 nalydadad.com. All rights reserved.
//

import UIKit
import AVFoundation

class MSRootViewController: UIViewController {
	let manager = MSCaptureManager()
	let resultImage = UIImageView()
	let resultText = UILabel()
	let toggle = UISwitch()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		resultImage.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(resultImage)
		NSLayoutConstraint.activate([
			resultImage.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
			resultImage.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
		])
		resultText.textColor = UIColor.systemPurple
		resultText.font = UIFont.systemFont(ofSize: 32)
		resultText.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(resultText)
		NSLayoutConstraint.activate([
			resultText.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
			resultText.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
		])
		toggle.addTarget(self, action: #selector(toggleDidChange), for: .valueChanged)
		toggle.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(toggle)
		NSLayoutConstraint.activate([
			toggle.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -20),
			toggle.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -100)
		])
		manager.delegate = self
		try? manager.start()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		displayMotionSense()
	}
	
	@objc func toggleDidChange() {
		displayMotionSense()
	}
	
	func displayMotionSense() {
		resultText.text = "Motion Sense"
		resultText.alpha = 0.0
		UIView.animate(withDuration: 1, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
			self.resultText.alpha = 1.0
		}, completion: nil)
	}
}


extension MSRootViewController: MSCaptureMangerDelegate {
	func captureManager(_ manager: MSCaptureManager, didOutput image: UIImage, result: MSMotionValidateResult) {
		if toggle.isOn {
			resultImage.image = image
			resultImage.bounds.size = image.size
			resultImage.isHidden = false
		}
		else {
			resultImage.isHidden = true
		}
		
		if result != .unknown {
			self.resultText.alpha = 1.0
			resultText.text = result == .left ? "left" : "right"
			resultText.sizeToFit()
			UIView.animate(withDuration: 1, delay: 0.5, options: UIView.AnimationOptions.curveEaseInOut, animations: {
				self.resultText.alpha = 0.0
			}, completion: nil)
		}
	}
}
