//
//  Building.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/01/27.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import RealmSwift
class Building: Object {
    @objc dynamic var id = ""
    @objc dynamic var research_id = ""
    @objc dynamic var owner_id = ""
    @objc dynamic var property_no = ""
    @objc dynamic var address = ""
    @objc dynamic var memo = ""

}
