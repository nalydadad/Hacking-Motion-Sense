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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		resultImage.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(resultImage)
		NSLayoutConstraint.activate([
			resultImage.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
			resultImage.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
		])
		// Do any additional setup after loading the view.
		manager.delegate = self
		try? manager.start()
	}
	
}


extension MSRootViewController: MSCaptureMangerDelegate {
	func captureManager(_ manager: MSCaptureManager, didOutput image: UIImage) {
		resultImage.image = image
		resultImage.bounds.size = image.size
	}
}
