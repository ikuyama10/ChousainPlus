//
//  TextNode.swift
//  ARplaneDitect
//
//  Created by yamaguchi on 2018/11/17.
//  Copyright © 2018 山口　郁準. All rights reserved.
//

import SceneKit
import ARKit

class TextNode: SCNNode {
    required init?(coder aDecoder: NSCoder) {
        fatalError("error")
    }
    init(str:String) {
        super.init()
        let text = SCNText(string: str, extrusionDepth: 0.01)
        text.font = UIFont(name: "Futura-Bold", size: 1)
        text.firstMaterial?.diffuse.contents = UIColor.white
        
        let textNode = SCNNode(geometry: text)
        self.addChildNode(textNode)
        let (max, min) = textNode.boundingBox
        let w = abs(CGFloat(max.x - min.x))
        let h = abs(CGFloat(max.y - min.y))
        //textNode.position = SCNVector3(-w/2, -h*1.2, 0)
        /*
        //背景
        let shape = SCNPlane(width: w*1.1, height: h)
        shape.firstMaterial?.diffuse.contents = UIColor.white
        let bkgndNode = SCNNode(geometry: shape)
        bkgndNode.opacity = 0.25
        bkgndNode.position = SCNVector3(0, h/2, 0)
        self.addChildNode(bkgndNode)
        */
        //縮小
        self.scale = SCNVector3(0.04,0.04,0.04)
    }
}
