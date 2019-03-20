//
//  PhotoManager.swift
//  ChousainPlus
//
//  Created by ZeroSpace on 2019/02/24.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import SceneKit
import RealmSwift
class PhotoManager: NSObject {
    func savePhoto(photo:UIImage, photo_mode:Int, division:String,photo_num:Int,photo_sub_num:Int, room_name :String, userid:String)->String{
        //SnapShotを保存する
        let jpgImage = photo.jpegData(compressionQuality: 1.0)
        //保存
        
        let now = Date() // 現在日時の取得
        let dateFormatter = DateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_JP") as Locale // ロケールの設定
        dateFormatter.dateFormat = "yyyyMMddHHmmss" // 日付フォーマットの設定
        
        //P+ 写真番号 + 日付
        //let filename = "P" + photo_num.description + "_" + dateFormatter.string(from: now as Date) + ".jpg"
        //P+ 写真番号 + UUID
        let uuid = NSUUID().uuidString
        let filename = "P" + photo_num.description + "_" + uuid + ".jpg"

        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // 日付フォーマットの設定
        let photo_at = dateFormatter.string(from: now as Date)
        
        //let documentsPath = NSHomeDirectory() + "/Documents"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(filename)
        print("save="+fileURL.path)
        do {
            try jpgImage!.write(to: fileURL)
            let recordData = RecordData()
            var kind = "0"
            if(photo_mode == 2){
                kind = "1"  //損傷
            }else if(photo_mode == 3){
                kind = "2" //接写
            }
            recordData.setKind(kind: kind)
            recordData.setDivision(division: division)
            recordData.setRoomName(room_name: room_name)
            if(userid != ""){
                recordData.setUserid(userid: userid)
            }
            recordData.setParameter()
            //2回目以降は、前回の写真がある場合、前回の写真のuseridをuseridに入れる
            
            recordData.savePhoto(fname: filename, date: photo_at, no: photo_num.description, subno: photo_sub_num.description)
            /*
            //division別に写真番号をカウントする------------------------------------------------------
            photo_num += 1
            
            if(kind != "0"){
                //写真編集画面へ
            }
             */
        } catch {
            //エラー処理
            print("Error")
        }
        return filename
    }
    func deletePhoto(filename:String){
        if( FileManager.default.fileExists( atPath: filename ) ) {
            do {
                try FileManager.default.removeItem( atPath: filename )
            } catch {
                print("写真削除失敗 " + filename)
            }
        } else {
            print("削除写真ファイルなし " + filename)
        }
    }
    func saveWorldMap(url:String, number:String, position:simd_float4x4){
        let realmCameraLocate = try! Realm()
        //データ
        let camera = CameraLocate()
        camera.url = url
        camera.number = number
        camera.m0x = position.columns.0.x
        camera.m0y = position.columns.0.y
        camera.m0z = position.columns.0.z
        camera.m1x = position.columns.1.x
        camera.m1y = position.columns.1.y
        camera.m1z = position.columns.1.z
        camera.m2x = position.columns.2.x
        camera.m2y = position.columns.2.y
        camera.m2z = position.columns.2.z
        camera.m3x = position.columns.3.x
        camera.m3y = position.columns.3.y
        camera.m3z = position.columns.3.z
       print ("camera pos=" + position.debugDescription)
        try! realmCameraLocate.write {
            realmCameraLocate.add(camera)
        }
    }
    func savePhotoWorldMap(url:String, number:String, position:simd_float4x4){
        let realmPhotoLocate = try! Realm()
        //データ
        let photo = PhotoLocate()
        photo.url = url
        photo.number = number
        photo.m0x = position.columns.0.x
        photo.m0y = position.columns.0.y
        photo.m0z = position.columns.0.z
        photo.m1x = position.columns.1.x
        photo.m1y = position.columns.1.y
        photo.m1z = position.columns.1.z
        photo.m2x = position.columns.2.x
        photo.m2y = position.columns.2.y
        photo.m2z = position.columns.2.z
        photo.m3x = position.columns.3.x
        photo.m3y = position.columns.3.y
        photo.m3z = position.columns.3.z
        print ("photo pos=" + position.debugDescription)
        try! realmPhotoLocate.write {
            realmPhotoLocate.add(photo)
        }
    }
}
