//
//  WhiteBoardDictionary.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/02/02.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import RealmSwift
class WhiteBoardDictionary: Object {
    @objc dynamic var wbid = ""
    @objc dynamic var wb_type = ""
    @objc dynamic var item_no = ""
    @objc dynamic var item_name = ""
    @objc dynamic var dsp_x = ""
    @objc dynamic var dsp_y = ""
    @objc dynamic var width = ""
    @objc dynamic var height = ""
    @objc dynamic var unit = ""
    @objc dynamic var rule = ""
}
