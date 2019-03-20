//
//  Photo.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/02/01.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import RealmSwift
class Photo: Object {
    @objc dynamic var id = ""
    @objc dynamic var userid = ""
    @objc dynamic var research_id = ""
    @objc dynamic var building_id = ""
    @objc dynamic var stage = ""
    @objc dynamic var division = ""
    @objc dynamic var kind = ""
    @objc dynamic var room_name = ""
    @objc dynamic var filmed_at = ""
    @objc dynamic var number = ""
    @objc dynamic var number_sub = ""
    @objc dynamic var label = ""
    @objc dynamic var url = ""
    @objc dynamic var wb_type = ""
    @objc dynamic var wb_id = ""
    @objc dynamic var item1 = ""
    @objc dynamic var item2 = ""
    @objc dynamic var item3 = ""
    @objc dynamic var item4 = ""
    @objc dynamic var item5 = ""
    @objc dynamic var item6 = ""
    @objc dynamic var item7 = ""
    @objc dynamic var item8 = ""
    @objc dynamic var item9 = ""
    @objc dynamic var item10 = ""

    @objc dynamic var status = "0" //送信済み
}
