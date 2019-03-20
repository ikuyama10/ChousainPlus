//
//  BoxNode.swift
//  ARplaneDitect
//
//  Created by yamaguchi on 2018/11/09.
//  Copyright © 2018 山口　郁準. All rights reserved.
//

import SceneKit
import ARKit

class BoxNode: SCNNode {
    required init?(coder aDecoder: NSCoder){
        fatalError("init(coder:) has not implemented")
    }
    init(width: CGFloat, height: CGFloat) {
        super.init()
        //let box = SCNBox(width: 0.03, height: 0.001, length: 0.03, chamferRadius: 0)
        let box = SCNBox(width: width, height: height, length: 0.002, chamferRadius: 0)
        //box.firstMaterial?.diffuse.contents = UIColor.red
        box.firstMaterial?.diffuse.contents = UIImage(named: "ipad.png")

        //transform = SCNMatrix4MakeRotation(-Float.pi, 0, 0, 0)
        geometry = box
    }
}
