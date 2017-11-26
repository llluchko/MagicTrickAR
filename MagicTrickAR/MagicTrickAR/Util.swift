//
//  Util.swift
//  MagicTrickAR
//
//  Created by Latchezar Mladenov on 11/26/17.
//  Copyright © 2017 Latchezar Mladenov. All rights reserved.
//

import SceneKit

class Util {
	
	static func loadNewNodeWith(url: String) -> SCNNode {
		let url = Bundle.main.url(forResource: url, withExtension: ".scn")!
		let hatNodeReference = SCNReferenceNode(url: url)!
		hatNodeReference.load()
		return hatNodeReference
	}
	
}
