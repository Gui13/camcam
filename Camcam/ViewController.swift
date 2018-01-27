//
//  ViewController.swift
//  Camcam
//
//  Created by Guillaume on 07/01/2018.
//  Copyright © 2018 Neolyse. All rights reserved.
//

import UIKit
import CoreMotion
import GLKit

import MjpegStreamingKit

class ViewController: UIViewController {
	
	let motion = CMMotionManager()
	let deviceQueue = OperationQueue()
	var timer : Timer?
	let pi_url = "http://192.168.1.24:9595"

	@IBOutlet weak var image: UIImageView!
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		self.startAccelerometer()
	
		let streamingController = MjpegStreamingController(imageView: self.image)
		// To play url do:
		let url = URL(string: "\(pi_url)/livecam")
		streamingController.play(url: url!)
		
	}
	
	func startAccelerometer() {
		if self.motion.isAccelerometerAvailable{
			self.motion.deviceMotionUpdateInterval = 1.0 / 15.0
			self.motion.accelerometerUpdateInterval = 1.0 / 15.0
			self.motion.showsDeviceMovementDisplay = true
			self.motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
			
			func toDeg(rad:Double) -> Double{
				return rad * 360.0 / (2*Double.pi)
			}			
			// Configure a timer to fetch the motion data.
			self.timer = Timer(fire: Date(),
							   interval: (1.0/15.0),
							   repeats: true,
							   block: { (timer) in
								if let data = self.motion.deviceMotion {
									let x = data.gravity.x
									let y = data.gravity.y
									let z = data.gravity.z
									let r = sqrt(x*x + y*y + z*z);
									let tiltForwardBackward = acos(z/r) * 180.0 / Double.pi - 90.0;
									
									self.tilt(deg: Int(tiltForwardBackward + 90))
									
									if let heading = self.headingCorrectedForTilt() {
										let headDeg = toDeg(rad: Double(heading))
										self.pan(deg: Int(180-headDeg))
									}
								} else {
									print("No motion data")
								}
			})
		}
		RunLoop.current.add(self.timer!, forMode: .defaultRunLoopMode)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func pan( deg: Int){
		print("Panning to \(deg)")
		if (deg < 0 || deg > 180){
			return
		}
		let panUrl = URL( string:"\(pi_url)/api/pan/\(deg)")
		URLSession.shared.dataTask(with: panUrl!).resume()
	}
	
	func tilt( deg: Int){
		print("Tilting to \(deg)")
		if (deg < 0 || deg > 180){
			return
		}
		let panUrl = URL( string:"\(pi_url)/api/tilt/\(deg)")
		URLSession.shared.dataTask(with: panUrl!).resume()
	}
	
	
	func headingCorrectedForTilt() -> Float?{
		guard let motion = self.motion.deviceMotion else{
			return nil
		}
		
		let aspect = fabsf(Float(self.view.bounds.width / self.view.bounds.height))
		let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0), aspect, 0.1, 100)
		
		
		let r = motion.attitude.rotationMatrix
		let camFromIMU = GLKMatrix4Make(Float(r.m11), Float(r.m12), Float(r.m13), 0,
										Float(r.m21), Float(r.m22), Float(r.m23), 0,
										Float(r.m31), Float(r.m32), Float(r.m33), 0,
										0,     0,     0,     1)
		
		let viewFromCam = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, 0);
		let imuFromModel = GLKMatrix4Identity
		let viewModel = GLKMatrix4Multiply(imuFromModel, GLKMatrix4Multiply(camFromIMU, viewFromCam))
		var isInvertible : Bool = false
		let modelView = GLKMatrix4Invert(viewModel, &isInvertible);
		var viewport = [Int32](repeating:0,count:4)
		
		viewport[0] = 0;
		viewport[1] = 0;
		viewport[2] = Int32(self.view.frame.size.width);
		viewport[3] = Int32(self.view.frame.size.height);
		
		var success: Bool = false
		let vector3 = GLKVector3Make(Float(self.view.frame.size.width)/2, Float(self.view.frame.size.height)/2, 1.0)
		let calculatedPoint = GLKMathUnproject(vector3, modelView, projectionMatrix, &viewport, &success)
		
		return success ? atan2f(-calculatedPoint.y, calculatedPoint.x) : nil
	}
	
}


