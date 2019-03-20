//
//  RecordData.swift
//  ARplaneDitectRecord
//
//  Created by yamaguchi on 2019/02/06.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import RealmSwift

class RecordData: Object {
    var userid :String = "0"
    //var company_id :String = "1"
    var research_id :String = "1"
    var building_id :String = "1"
    var stage :String = "1"
    var division :String = "0"
    var kind:String = "0"
    var room_name :String = ""
    var wb_type :String = "1"   //divisionからDBより決まる
    var wb_id :String = "1"
    
    //保存ファイル名
    //C(company_id)/R(research_id)/B(building_id)/S(stage)/D(division)/yyyymmddhhmm.jpg
    
    func setParameter(){
        let defaults = UserDefaults.standard
        //2回目以降は、前回の写真のuseridを入れる(前回が有る場合)
        self.userid = defaults.string(forKey: "userid")!
        self.research_id = defaults.string(forKey: "research_id")!
        self.building_id = defaults.string(forKey: "building_id")!
        self.stage = defaults.string(forKey: "stage")!
        self.wb_type = self.division
        
        let realmWhiteBoard = try! Realm()
        let results = realmWhiteBoard.objects(WhiteBoardMaster.self).filter("wb_type == %@", self.wb_type)
        self.wb_id = results[0].wbid
    }
    func setRoomName(room_name :String){
        self.room_name = room_name
    }
    func setUserid(userid :String){
        self.userid = userid
    }
    func setDivision(division :String){
        self.division = division
        self.wb_type = division
        let realmWhiteBoardMaster = try! Realm()
        let whiteBoardMasters = realmWhiteBoardMaster.objects(WhiteBoardMaster.self).filter("wb_type == %@", self.wb_type)
        self.wb_id = whiteBoardMasters[0].wbid
    }
    func setKind(kind :String){
        self.kind = kind
    }
    func savePhoto(fname : String, date : String, no :String, subno: String){
        print(Realm.Configuration.defaultConfiguration.fileURL!)

        let realmPhoto = try! Realm()
        //データ
        let photo = Photo()
        photo.url = fname
        photo.userid = userid
        photo.filmed_at = date
        photo.research_id = research_id
        photo.building_id = building_id
        photo.stage = stage
        photo.division = division
        photo.kind = kind
        photo.room_name = room_name
        photo.wb_type = wb_type
        photo.wb_id = wb_id
        photo.number = no
        photo.number_sub = subno
        photo.label = no //-----------------------------------暫定
        photo.status = "1"
        try! realmPhoto.write {
            realmPhoto.add(photo)
        }
        
        /*
        let realmPhotoList = try! Realm()
        //データ
        let photoNew = PhotoNew()
        if stage == "1"{
            photoNew.url1 = fname
        }else{
            photoNew.url2 = fname
        }
        photoNew.stage = stage
        photoNew.division = division
        photoNew.kind = kind
        photoNew.room_name = room_name
        photoNew.wb_id = wb_id
        photoNew.number = no
        photoNew.number_sub = subno
        photoNew.label = no //-----------------------------------暫定
        photoNew.status = "1"
        try! realmPhotoList.write {
            realmPhotoList.add(photoNew)
        }
         */
    }
    func saveWhiteboard(filename :String){
        let realmPhoto = try! Realm()
        var photoCollection = realmPhoto.objects(Photo.self)
        photoCollection = realmPhoto.objects(Photo.self).filter("url == %@", filename)
        //データ
        let photo = photoCollection[0]
        let whiteBoard = WhiteBoardData.shared
        try! realmPhoto.write {
            photo.item1 = whiteBoard.items[0]
            photo.item2 = whiteBoard.items[1]
            photo.item3 = whiteBoard.items[2]
            photo.item4 = whiteBoard.items[3]
            photo.item5 = whiteBoard.items[4]
            photo.item6 = whiteBoard.items[5]
            photo.item7 = whiteBoard.items[6]
            photo.item8 = whiteBoard.items[7]
            photo.item9 = whiteBoard.items[8]
            photo.item10 = whiteBoard.items[9]
        }
    }
    /*
    func getLastPhoto() -> String{
        let realmPhotos = try! Realm()
        let results = realmPhotos.objects(Photo.self)
        let obj = results.last
        let filename = obj?.filename
        
        return filename!
    }
 */
}
