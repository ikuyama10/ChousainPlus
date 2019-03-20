//
//  PlaneNode.swift
//  ARplaneDitect
//
//  Created by yamaguchi on 2018/11/09.
//  Copyright © 2018 山口　郁準. All rights reserved.
//

import SceneKit
import ARKit

class PlaneNode : SCNNode {
    required init?(coder aDecoder: NSCoder){
        fatalError("init(coder:) has not implemented")
    }
    init(anchor: ARPlaneAnchor){
        super.init()
        
        let plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        plane.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.25)
        plane.widthSegmentCount = 10
        plane.heightSegmentCount = 10
        
        geometry = plane
        //90度回転
        transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        position = SCNVector3(anchor.center.x, 0, anchor.center.y)
    }
    func update(anchor: ARPlaneAnchor){
        let plane = geometry as! SCNPlane
        plane.width = CGFloat(anchor.extent.x)
        plane.height = CGFloat(anchor.extent.z)
        
        position = SCNVector3(anchor.center.x, 0, anchor.center.y)
    }
}
