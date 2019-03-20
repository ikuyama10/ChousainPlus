//
//  RoomMap.swift
//  ChousainPlus
//
//  Created by ZeroSpace on 2019/03/09.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import RealmSwift
class RoomMap: Object {
    @objc dynamic var research_id = ""
    @objc dynamic var building_id = ""
    @objc dynamic var stage = ""
    @objc dynamic var room_name = ""
    @objc dynamic var filename = ""
    override static func primaryKey() -> String? {
        return "filename"
    }
    
}
