//
//  ViewController.swift
//  MagicTrickAR
//
//  Created by Latchezar Mladenov on 11/26/17.
//  Copyright © 2017 Latchezar Mladenov. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class MagicSceneViewController: UIViewController {

	// MARK: - IBActions
	@IBAction func pressMagicButton(_ sender: Any) {
		guard let magicHat = magicHat, let ballsContainer = ballsContainer else { return }

		self.magicEnabled = !self.magicEnabled
		
		for i in (0 ..< ballsContainer.childNodes.count).reversed() {
			let ball = ballsContainer.childNodes[i]
			
			// check if the balls center is within the bounds of the hat
			if magicHat.boundingBoxContains(ball) {
				ball.isHidden = self.magicEnabled
			}
		}
	}
	
	@IBAction func pressThrowButton(_ sender: Any) {
		let (cameraDirection, cameraPosition) = getCameraDirectionAndPosition()
		let ball = Ball()
		ball.position = cameraPosition

		let force: Float = 2.0
		let ballForce = SCNVector3(cameraDirection.x * force, cameraDirection.y * force, cameraDirection.z * force)
		if let ballPhysicsBody = ball.physicsBody {
			ballPhysicsBody.applyForce(ballForce, asImpulse: true)
		}

		ballsContainer?.addChildNode(ball)
	}
	
	// MARK: - IBOutlets
	@IBOutlet var sceneView: ARSCNView!
	@IBOutlet weak var magicButton: UIButton!
	@IBOutlet weak var throwButton: UIButton!
	
	// MARK: - Properties
	var ballsContainer : SCNNode?
	
	var magicHat: Hat? {
		get {
			return sceneView.scene.rootNode.childNode(withName: "Hat", recursively: true) as? Hat
		}
	}
	
	var magicEnabled: Bool = false
	
	// MARK: - Lifecycle methods
	override func viewDidLoad() {
		super.viewDidLoad()
		sceneView.delegate = self
		let scene = SCNScene()
		sceneView.scene = scene
		
		// create node to hold the balls
		ballsContainer = SCNNode()
		sceneView.scene.rootNode.addChildNode(ballsContainer!)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard ARWorldTrackingConfiguration.isSupported else {
			fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """)
		}

		let configuration = ARWorldTrackingConfiguration()
		configuration.planeDetection = .horizontal
		sceneView.session.run(configuration)
		sceneView.session.delegate = self
		UIApplication.shared.isIdleTimerDisabled = true
		
		// Show debug UI to view performance metrics (e.g. frames per second).
		//sceneView.showsStatistics = true
		//self.sceneView.debugOptions = [.showConstraints, .showPhysicsShapes, ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
		
		self.sceneView.autoenablesDefaultLighting = true
		self.sceneView.automaticallyUpdatesLighting = true
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		sceneView.session.pause()
	}
	
	func positionMagicHat(_ position: SCNVector3, node: SCNNode) {
		let magichat = Hat()
		magichat.position = position
		node.addChildNode(magichat)
		magichat.isHidden = false
	}

	func getCameraDirectionAndPosition() -> (SCNVector3, SCNVector3) {
		if let frame = self.sceneView.session.currentFrame {
			let mat = SCNMatrix4(frame.camera.transform) // 4x4 transform matrix describing camera in world space
			let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33) // orientation of camera in world space
			let pos = SCNVector3(mat.m41, mat.m42, mat.m43) // location of camera in world space
			
			return (dir, pos)
		}
		return (SCNVector3(0, 0, -1), SCNVector3(0, 0, -0.2))
	}
	
}

// MARK: - ARSCNViewDelegate
extension MagicSceneViewController: ARSCNViewDelegate {
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		// Create an SNCPlane on the ARPlane
		guard let planeAnchor = anchor as? ARPlaneAnchor else {
			return
		}
		
		let planePadding: CGFloat = 10
		let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x) * planePadding,
												 height: CGFloat(planeAnchor.extent.z) * planePadding)
		
		let planeMaterial = SCNMaterial()
		planeMaterial.diffuse.contents = UIColor.clear
		plane.materials = [planeMaterial]
		
		let planeNode = SCNNode(geometry: plane)
		planeNode.position = SCNVector3Make(
			planeAnchor.center.x - Float(plane.width - CGFloat(planeAnchor.extent.x)/2),
			0,
			planeAnchor.center.z - Float(plane.height - CGFloat(planeAnchor.extent.z)/2))
		planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
		
		let physicsBody = SCNPhysicsBody(type: .kinematic, shape: nil)
		physicsBody.friction = 0.8
		planeNode.physicsBody = physicsBody
		node.addChildNode(planeNode)
		
		positionMagicHat(SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z), node: node)
	}
	
	func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
		guard let planeAnchor = anchor as?  ARPlaneAnchor,
			let planeNode = node.childNodes.first,
			let plane = planeNode.geometry as? SCNPlane
			else { return }
		
		planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
		plane.width = CGFloat(planeAnchor.extent.x)
		plane.height = CGFloat(planeAnchor.extent.z)
	}
}

// MARK: - ARSessionObserver
extension MagicSceneViewController: ARSessionObserver {
	func session(_ session: ARSession, didFailWithError error: Error) {
		print("Session failed: \(error.localizedDescription)")
		resetTracking()
	}
	
	func sessionWasInterrupted(_ session: ARSession) {
		print("Session was interrupted")
	}
	
	func sessionInterruptionEnded(_ session: ARSession) {
		print("Session interruption ended")
		resetTracking()
	}
	
	private func resetTracking() {
		let configuration = ARWorldTrackingConfiguration()
		configuration.planeDetection = .horizontal
		sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
	}
}

// MARK: - ARSessionDelegate
extension MagicSceneViewController: ARSessionDelegate {
	func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
		guard let frame = session.currentFrame else { return }
		updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
	}
	
	func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
		guard let frame = session.currentFrame else { return }
		updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
	}
	
	func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
		updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
	}
	
	private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
		// Update the UI to provide feedback on the state of the AR experience.
		let message: String
		
		switch trackingState {
		case .normal where frame.anchors.isEmpty:
			message = "Move the device around to detect horizontal surfaces."
		case .normal:
			message = ""
		case .notAvailable:
			message = "Tracking unavailable."
		case .limited(.excessiveMotion):
			message = "Tracking limited - Move the device more slowly."
		case .limited(.insufficientFeatures):
			message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
		case .limited(.initializing):
			message = "Initializing AR session."
		}
		print(message)
	}
}
