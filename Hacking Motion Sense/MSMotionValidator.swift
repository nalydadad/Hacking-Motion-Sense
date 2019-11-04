//
//  MSMotionValidator.swift
//  Hacking Motion Sense
//
//  Created by DADA on 2019/10/31.
//  Copyright © 2019 nalydadad.com. All rights reserved.
//

import UIKit

enum MSMotionValidateResult {
	case left, right, unknown
}

class MSMotionValidator: NSObject {
	
	private var lastPoint: CGPoint?
	private var lastSpeedX: CGFloat?

	func validate(input: CGPoint) -> MSMotionValidateResult {
		guard input != .zero else {
			self.lastPoint = nil
			return .unknown
		}
		var newResult: MSMotionValidateResult = .unknown
		if let lastPoint = self.lastPoint {
			let newSpeedX = input.x - lastPoint.x
			let newSpeedY = input.y - lastPoint.y
			if (abs(newSpeedX) > 90 && abs(newSpeedY) < 50) {
				newResult = newSpeedX < 0 ? .left : .right
			}
		}
		self.lastPoint = input
		return newResult
	}
	
}
