//
//  Hat.swift
//  MagicTrickAR
//
//  Created by Latchezar Mladenov on 28.11.17.
//  Copyright © 2017 Latchezar Mladenov. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class Hat: SCNNode {
	
	// MARK: - Properties
	var tubeNode: SCNNode?
	
	// MARK: init methods
	override init() {
		super.init()
		guard let scene = SCNScene(named: "hat.scn", inDirectory: "art.scnassets")
			else {
				fatalError("Unable to find scene")
		}
		self.name = "Hat"
		initFromScene(scene)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	private func initFromScene(_ scene: SCNScene) {
		guard let hat = scene.rootNode.childNode(withName: "hat", recursively: true) else {
			fatalError("Failed to find child with the name hat")
		}
		for childNode in hat.childNodes {
			if let name = childNode.name {
				if name == "middle" {
					tubeNode = childNode
					break
				}
			}
		}
		hat.position = SCNVector3(0, 0, 0)
		self.addChildNode(hat)
	}
	
	func boundingBoxContains(_ node: SCNNode) -> Bool {
		return self.boundingBoxContains(node.presentation.worldPosition)
	}
	
	func boundingBoxContains(_ point: SCNVector3) -> Bool {
		let node = self.tubeNode ?? self
		var (min, max) = node.presentation.boundingBox
		
		let size = max - min
		min = SCNVector3(self.worldPosition.x - size.x/2, self.worldPosition.y, self.worldPosition.z - size.z/2)
		max = SCNVector3(self.worldPosition.x + size.x/2, self.worldPosition.y + size.y, self.worldPosition.z + size.z/2)
		
		return
				point.x >= min.x  &&
				point.y >= min.y  &&
				point.z >= min.z  &&
				
				point.x < max.x  &&
				point.y < max.y  &&
				point.z < max.z
	}
}
