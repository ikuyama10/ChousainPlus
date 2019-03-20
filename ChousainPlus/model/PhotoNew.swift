//
//  PhotoNew.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/02/08.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import RealmSwift

class PhotoNew: Object {
    //@objc dynamic var id = ""
    @objc dynamic var stage = ""
    @objc dynamic var division = ""
    @objc dynamic var kind = ""
    @objc dynamic var room_name = ""
    @objc dynamic var number = ""
    @objc dynamic var number_sub = ""
    @objc dynamic var userid = ""
    @objc dynamic var label = ""
    @objc dynamic var url1 = ""
    @objc dynamic var url2 = ""
    @objc dynamic var wb_id = ""

    @objc dynamic var status = "0" //送信済み
}

