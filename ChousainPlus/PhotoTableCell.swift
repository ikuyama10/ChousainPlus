//
//  PhotoTableCell.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/01/27.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit

class PhotoTableCell: UITableViewCell {

    @IBOutlet weak var photo_number: UILabel!
    @IBOutlet weak var Photo1: UIImageView!
    @IBOutlet weak var Photo2: UIImageView!
    @IBOutlet weak var status: UILabel!
    @IBOutlet weak var button: UIButton!
    
    @IBOutlet weak var btnCloseup: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    /*
    override func awakeFromNib() {
        super.awakeFromNib()
        self.Photo1.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(self.onTapIcon(_:))))
        
    }
    @objc func onTapIcon(_ sender : UITapGestureRecognizer)  {
        print("アイコンがタップされました!!")
    }
    */
}
