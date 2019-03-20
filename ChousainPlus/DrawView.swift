//
//  DrawView.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/03/19.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit

class DrawView: UIView {
    class Line {
        var points: [CGPoint]
        var color :CGColor
        var width: CGFloat
        
        init(color: CGColor, width: CGFloat){
            self.color = color
            self.width = width
            self.points = []
        }
        
        func drawOnContext(context: CGContext){
            UIGraphicsPushContext(context)
            
            context.setStrokeColor(self.color)
            context.setLineWidth(self.width)
            context.setLineCap(CGLineCap.round)
            
            // 2点以上ないと線描画する必要なし
            if self.points.count > 1 {
                for (index, point) in self.points.enumerated() {
                    if index == 0 {
                        //context.MoveToPoint(context, point.x, point.y)
                        context.move(to: point)
                    } else {
                        //context.AddLineToPoint(context, point.x, point.y)
                        context.addLine(to: point)
                    }
                }
            }
            context.strokePath()
            
            UIGraphicsPopContext()
        }
    }
    var lines: [Line] = []
    var currentLine: Line? = nil
    private var currentImage: UIImage? = nil
    private var myColor :CGColor = UIColor.red.cgColor
    private var myWidth :CGFloat = 3.0
     // タッチされた
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self)
        currentLine = Line(color: myColor, width: myWidth)
        currentLine?.points.append(point)
    }
    
    // タッチが動いた
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let point = touches.first!.location(in: self)
        currentLine?.points.append(point)
        self.setNeedsDisplay()
    }
    // タッチが終わった
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 2点以上のlineしか保存する必要なし
        if (currentLine?.points.count)! > 1 {
            lines.append(currentLine!)
        }
        
        currentLine = nil
        self.setNeedsDisplay()
    }
    func resetContext(context: CGContext) {
        context.clear(self.bounds)
        if let color = self.backgroundColor {
            color.setFill()
        } else {
            UIColor.white.setFill()
        }
        context.fill(self.bounds)
    }
    func clearDraw(){
        lines = []
        currentLine = nil
        currentImage = nil
        self.setNeedsDisplay()
    }
    func setColor(color:CGColor){
        self.myColor = color
    }
    func setWidth(width :CGFloat){
        self.myWidth = width
    }
    //描画設定
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()!
        //画面を一旦初期化
        resetContext(context: context)
        
        // 描き終わったline
        for line in lines {
            line.drawOnContext(context: context)
        }
        
        // 描いてる途中のline
        if let line = currentLine {
            line.drawOnContext(context: context)
        }
    }
    func getCurrentImage() -> UIImage {
        // キャプチャする範囲を取得する
        let rect = self.bounds
        
        // ビットマップ画像のcontextを作成する
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        let context : CGContext = UIGraphicsGetCurrentContext()!
        
        // view内の描画をcontextに複写する
        self.layer.render(in: context)
        
        // contextのビットマップをUIImageとして取得する
        let image : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        // contextを閉じる
        UIGraphicsEndImageContext()
        
        return image
    }
}
