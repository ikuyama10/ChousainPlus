//
//  SyncViewController.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/02/01.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire

class SyncViewController: UIViewController {
    var dic  = [String : Any]()
    var mode = 1
    var taskEnd = false;
    var start = false;
    var company_id = "0"
    var research_id = "0"
    var building_id = "0"
    let defaults = UserDefaults.standard
    let httpManager = HttpManager()
    var DownloadCnt = 0
    
     
    @IBOutlet weak var progressBar: UIProgressView!
    override func viewDidLoad() {
        super.viewDidLoad()
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        // Do any additional setup after loading the view.
        progressBar.setProgress(0.0, animated: false)
    }
    

    @IBAction func cancel(_ sender: Any) {
        self.performSegue(withIdentifier: "Research", sender: self)
    }
    @IBAction func syncData(_ sender: Any) {
        //未送信の写真を確認---------------------------------------------------------------
        //未送信の写真がある場合、先にアップロードを行う
        //未送信ファイルのチェック
        let realmPhoto = try! Realm()
        let photoCollection = realmPhoto.objects(Photo.self)
        var bUpload = false
        for photo in photoCollection {
            if photo.status != "0"{
                //未送信ファイルあり
                bUpload = true
                break
            }
        }
        
        let userid = self.defaults.string(forKey: "userid")
        let keycode = self.defaults.string(forKey: "keycode")
        //self.research_id = self.defaults.string(forKey: "research_id")
        //self.building_id = self.defaults.string(forKey: "building_id")

        //変更のあったデータのみダウンロードする
        while(taskEnd == false){
            if(start == false){
                start = true
                switch(mode){
                case 1:
                    //ユーザー基本データのダウンロード
                    print("getinfo")
                    self.httpPost(call: "getInfo.php",parameter: "userid=" + userid! + "&keycode=" + keycode!)
                    break
                case 2:
                    //調査マスターデータのダウンロード
                    print("getResearch_masters")
                    self.httpPost(call: "getResearchStages.php",parameter: "company_id=" + String(self.company_id) + "&keycode=" + keycode!)
                    break
                case 3:
                    //調査データのダウンロード
                    print("getResearches")
                    self.httpPost(call: "getResearches.php",parameter: "company_id=" + String(self.company_id) + "&keycode=" + keycode!)
                    break
                case 4:
                    //物件データのダウンロード
                    print("getBuildings")
                    self.httpPost(call: "getBuildings.php",parameter: "company_id=" + String(self.company_id) + "&keycode=" + keycode!)
                    break
                case 5:
                    //写真情報のダウンロード
                    print("getPhotos")
                    self.httpPost(call: "getPhotos.php",parameter: "company_id=" + String(self.company_id) + "&keycode=" + keycode!)
                    break
                case 6:
                    //白板マスターデータダウンロード
                    print("getWhiteBoardMasters")
                    self.httpPost(call: "getWhiteBoardMasters.php",parameter: "company_id=" + String(self.company_id) + "&keycode=" + keycode!)
                    break
                case 7:
                    //白板定義データダウンロード
                    print("getWhiteBoardDictionaries")
                    //更新日時を送信　変更時にデータ送信
                    self.httpPost(call: "getWhiteBoardDictionaries.php",parameter: "company_id=" + String(self.company_id) + "&keycode=" + keycode!)
                    break
                case 8:
                    //所有者データダウンロード
                    print("getOwners")
                    self.httpPost(call: "getOwners.php",parameter: "company_id=" + String(self.company_id) + "&keycode=" + keycode!)
                    break
                case 9:
                    //辞書データダウンロード
                    print("getDictionaries")
                    self.httpPost(call: "getDictionaries.php",parameter: "company_id=" + String(self.company_id) + "&keycode=" + keycode!)
                    break
                case 10:
                    //RoomMapダウンロード
                    print("getRoomMaps")
                    self.httpPost(call: "getRoomMaps.php",parameter: "company_id=" + String(self.company_id) + "&keycode=" + keycode!)
                    break
                case 11:
                    //Camera位置ダウンロード
                    print("getCameraLocations")
                    self.httpPost(call: "getCameraLocations.php",parameter: "company_id=" + String(self.company_id) + "&keycode=" + keycode!)
                    break
                case 12:
                    //Photo位置ダウンロード
                    print("getPhotoLocations")
                    self.httpPost(call: "getPhotoLocations.php",parameter: "company_id=" + String(self.company_id) + "&keycode=" + keycode!)
                    break
                case 20:
                    //新規追加分を追加　　新規削除分を削除
                    downloadPhoto()
                    mode = 21
                    start = false
                    //ダウンロード終了を待つ
                    break
                case 21:
                    //新規追加分を追加　　新規削除分を削除
                    downloadRoomMap()
                    mode = 99
                    start = false
                    break
                case 99:
                    start = false
                    //ダウンロード終了まで画面を繊維させない
                    if self.DownloadCnt <= 1 {
                        taskEnd = true
                        //start = false
                    }
                    break
                default:
                    break
                }
            }
        }
        //
        performSegue(withIdentifier: "Research", sender: nil)
    }
    func httpPost(call : String, parameter: String){
        let url = URL(string: httpManager.getUrl() + call)
        var request = URLRequest(url: url!)
        // POSTを指定
        request.httpMethod = "POST"
        // POSTするデータをBodyとして設定
        request.httpBody = parameter.data(using: .utf8)
        let session = URLSession.shared
        //DispatchQueue.global().async {
        session.dataTask(with: request) { (data, response, error) in
            if error == nil, let data = data, let response = response as? HTTPURLResponse {
                // HTTPヘッダの取得
                print("Content-Type: \(response.allHeaderFields["Content-Type"] ?? "")")
                // HTTPステータスコード
                print("statusCode: \(response.statusCode)")
                print(String(data: data, encoding: .utf8) ?? "")
                // JSONからDictionaryへ変換
                session.finishTasksAndInvalidate()
                self.AnalsysResuls(data: data)
            }
            }.resume()
        //}
    }
    func AnalsysResuls(data: Data){
        switch(mode){
        case 1:
            print("respons 1")
            self.dic.removeAll()
            self.dic = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
            
            company_id = self.dic["company_id"] as! String
            let name = self.dic["name"] as! String
            self.defaults.set(company_id, forKey:"company_id")
            self.defaults.set(name, forKey:"company_name")
            
            DispatchQueue.main.async {
                self.progressBar.setProgress(0.01, animated: false)
            }
            mode = 2
            start = false
            break;
        case 2:
            print("respons 2")
            let realmResearchStages = try! Realm()
            
            //全データ削除
            try! realmResearchStages.write {
                realmResearchStages.deleteAll()
            }
            //調査データ
            //同じ　master_id で最新のものが今回のステージ
            let rows = try! httpManager.parse(json: String(data: data, encoding: .utf8) ?? "")
            for row in rows {
                let research = ResearchStage()
                research.id = row["id"] as! String
                research.name = row["name"] as! String
                research.stage = row["stage"] as! String
                //research.stage = "3" //---------------------------------------debug
                research.stage_name = row["stage_name"] as! String
                try! realmResearchStages.write {
                    realmResearchStages.add(research)
                }
            }
            DispatchQueue.main.async {
                self.progressBar.setProgress(0.02, animated: false)
            }
            mode = 3
            start = false
            break;
        case 3:
            let res = String(data: data, encoding: .utf8) ?? ""
            if res == "null" {
                mode = 99
                break
            }
            print("respons 3")
            let realmResearches = try! Realm()
            //調査データ
            //同じ　master_id で最新のものが今回のステージ
            let rows = try! httpManager.parse(json: String(data: data, encoding: .utf8) ?? "")
            for row in rows {
                let research = Research()
                research.id = row["id"] as! String
                research.name_first = row["name_first"] as! String
                research.name_second = nullCk(str: row["name_second"] as! String)
                research.stage = nullCk(str: row["stage"] as! String)
                research.stage_name = nullCk(str: row["stage_name"] as! String)
                try! realmResearches.write {
                    realmResearches.add(research)
                }
            }
            DispatchQueue.main.async {
                self.progressBar.setProgress(0.02, animated: false)
            }
            mode = 4
            start = false
            break;
        case 4:
            let res = String(data: data, encoding: .utf8) ?? ""
            if res == "null" {
                mode = 99
                break
            }
            print("respons 4")
            let realmBuildings = try! Realm()
            //建物データ
            let rows = try! httpManager.parse(json: String(data: data, encoding: .utf8) ?? "")
            for row in rows {
                let building = Building()
                building.id = row["id"] as! String
                building.research_id = nullCk(str: row["research_id"] as! String)
                building.owner_id = nullCk(str: row["owner_id"] as! String)
                building.property_no = nullCk(str: row["property_no"] as! String)
                building.address = nullCk(str: row["address"] as! String)
                building.memo = nullCk(str: row["memo"] as! String)
                try! realmBuildings.write {
                    realmBuildings.add(building)
                }
            }
            DispatchQueue.main.async {
                self.progressBar.setProgress(0.03, animated: false)
            }
            mode = 5
            start = false
            break;
        case 5:
            print("respons 5")
            let realmPhotos = try! Realm()
            //写真データ
            let rows = try! httpManager.parse(json: String(data: data, encoding: .utf8) ?? "")
            for row in rows {
                let photo = Photo()
                photo.id = row["id"] as! String
                photo.userid = row["userid"] as! String
                photo.research_id = row["research_id"] as! String
                photo.building_id = row["building_id"] as! String
                photo.stage = row["stage"] as! String
                photo.division = row["division"] as! String
                photo.kind = row["kind"] as! String
                photo.room_name = row["room_name"] as! String
                photo.filmed_at = row["filmed_at"] as! String
                photo.number = row["no"] as! String
                photo.number_sub = row["subno"] as! String
                photo.label = row["label"] as! String
                photo.url = row["url"] as! String
                photo.wb_type = row["wb_type"] as! String
                photo.wb_id = row["wb_id"] as! String
                photo.item1 = row["item1"] as! String
                photo.item2 = row["item2"] as! String
                photo.item3 = row["item3"] as! String
                photo.item4 = row["item4"] as! String
                photo.item5 = row["item5"] as! String
                photo.item6 = row["item6"] as! String
                photo.item7 = row["item7"] as! String
                photo.item8 = row["item8"] as! String
                photo.item9 = row["item9"] as! String
                photo.item10 = row["item10"] as! String
                
                try! realmPhotos.write {
                    realmPhotos.add(photo)
                }
            }
            DispatchQueue.main.async {
                self.progressBar.setProgress(0.04, animated: false)
            }
            mode = 6
            start = false
            break;
        case 6:
            print("respons 6")
            let realmWhiteBoardMasters = try! Realm()
            //白板マスターデータ
            let rows = try! httpManager.parse(json: String(data: data, encoding: .utf8) ?? "")
            for row in rows {
                let whiteBoardMaster = WhiteBoardMaster()
                whiteBoardMaster.wbid = row["wbid"] as! String
                whiteBoardMaster.wb_type = row["wb_type"] as! String
                try! realmWhiteBoardMasters.write {
                    realmWhiteBoardMasters.add(whiteBoardMaster)
                }
            }
            
            mode = 7
            start = false
            break;
        case 7:
            print("respons 7")
            let realmWhiteBoardDictionaries = try! Realm()
            //白板定義ーデータ
            let rows = try! httpManager.parse(json: String(data: data, encoding: .utf8) ?? "")
            //白板マスターがない場合はエラー
            
            for row in rows {
                let whiteBoardDictionary = WhiteBoardDictionary()
                whiteBoardDictionary.wbid = row["wbid"] as! String
                whiteBoardDictionary.wb_type = row["wb_type"] as! String
                whiteBoardDictionary.item_no = row["item_no"] as! String
                whiteBoardDictionary.item_name = row["item_name"] as! String
                whiteBoardDictionary.dsp_x = row["dsp_x"] as! String
                whiteBoardDictionary.dsp_y = row["dsp_y"] as! String
                whiteBoardDictionary.width = row["width"] as! String
                whiteBoardDictionary.height = row["height"] as! String
                whiteBoardDictionary.unit = row["unit"] as! String
                whiteBoardDictionary.rule = row["rule"] as! String
               try! realmWhiteBoardDictionaries.write {
                    realmWhiteBoardDictionaries.add(whiteBoardDictionary)
                }
            }
            
            mode = 8
            start = false
            break;
        case 8:
            print("respons 8")
            let realmOwners = try! Realm()
            //所有者ーデータ
            let rows = try! httpManager.parse(json: String(data: data, encoding: .utf8) ?? "")
            for row in rows {
                let owner = Owner()
                owner.id = row["id"] as! String
                owner.owner_number = row["owner_number"] as! String
                owner.owner_name = row["owner_name"] as! String
                try! realmOwners.write {
                    realmOwners.add(owner)
                }
            }
            
            mode = 9
            start = false
            break;
        case 9:
            print("respons 9")
            let realmDictionaries = try! Realm()
            //白板定義ーデータ
            let rows = try! httpManager.parse(json: String(data: data, encoding: .utf8) ?? "")
            for row in rows {
                let dictionary = Dictionary()
                dictionary.wbid = row["wbid"] as! String
                dictionary.item_no = row["item_no"] as! String
                dictionary.item_id = row["no"] as! String
                dictionary.item = row["item"] as! String
                try! realmDictionaries.write {
                    realmDictionaries.add(dictionary)
                }
            }
            
            mode = 10
            start = false
            break;
        case 10:
            print("respons 10")
            let realmRoomMap = try! Realm()
            //RoomMapーデータ
            let rows = try! httpManager.parse(json: String(data: data, encoding: .utf8) ?? "")
            for row in rows {
                let roomMap = RoomMap()
                roomMap.building_id = row["building_id"] as! String
                roomMap.stage = row["stage"] as! String
                roomMap.room_name = row["room_name"] as! String
                roomMap.filename = row["filename"] as! String
                try! realmRoomMap.write {
                    realmRoomMap.add(roomMap)
                }
            }
            
            mode = 11
            start = false
            break;
        case 11:
            print("respons 11")
            let realmCameraLocate = try! Realm()
            //RoomMapーデータ
            let rows = try! httpManager.parse(json: String(data: data, encoding: .utf8) ?? "")
            for row in rows {
                let cameraLocate = CameraLocate()
                cameraLocate.url = row["url"] as! String
                cameraLocate.number = row["number"] as! String
                var str = row["m0x"] as! String
                cameraLocate.m0x = Float(str)!
                str = row["m0y"] as! String
                cameraLocate.m0y = Float(str)!
                str = row["m0z"] as! String
                cameraLocate.m0z = Float(str)!
                str = row["m1x"] as! String
                cameraLocate.m1x = Float(str)!
                str = row["m1y"] as! String
                cameraLocate.m1y = Float(str)!
                str = row["m1z"] as! String
                cameraLocate.m1z = Float(str)!
                str = row["m2x"] as! String
                cameraLocate.m2x = Float(str)!
                str = row["m2y"] as! String
                cameraLocate.m2y = Float(str)!
                str = row["m2z"] as! String
                cameraLocate.m2z = Float(str)!
                str = row["m3x"] as! String
                cameraLocate.m3x = Float(str)!
                str = row["m3y"] as! String
                cameraLocate.m3y = Float(str)!
                str = row["m3z"] as! String
                cameraLocate.m3z = Float(str)!
                
                try! realmCameraLocate.write {
                    realmCameraLocate.add(cameraLocate)
                }
            }
            
            mode = 12
            start = false
            break;
        case 12:
            print("respons 12")
            let realmPhotoLocate = try! Realm()
            //RoomMapーデータ
            let rows = try! httpManager.parse(json: String(data: data, encoding: .utf8) ?? "")
            for row in rows {
                let photoLocate = PhotoLocate()
                photoLocate.url = row["url"] as! String
                photoLocate.number = row["number"] as! String
                var str = row["m0x"] as! String
                photoLocate.m0x = Float(str)!
                str = row["m0y"] as! String
                photoLocate.m0y = Float(str)!
                str = row["m0z"] as! String
                photoLocate.m0z = Float(str)!
                str = row["m1x"] as! String
                photoLocate.m1x = Float(str)!
                str = row["m1y"] as! String
                photoLocate.m1y = Float(str)!
                str = row["m1z"] as! String
                photoLocate.m1z = Float(str)!
                str = row["m2x"] as! String
                photoLocate.m2x = Float(str)!
                str = row["m2y"] as! String
                photoLocate.m2y = Float(str)!
                str = row["m2z"] as! String
                photoLocate.m2z = Float(str)!
                str = row["m3x"] as! String
                photoLocate.m3x = Float(str)!
                str = row["m3y"] as! String
                photoLocate.m3y = Float(str)!
                str = row["m3z"] as! String
                photoLocate.m3z = Float(str)!
                try! realmPhotoLocate.write {
                    realmPhotoLocate.add(photoLocate)
                }
            }
            
            mode = 20
            start = false
            break;
        default: break
        }
    }
    func downloadPhoto(){
        print("Download")
        //写真リスト
        let realmPhotos = try! Realm()
        
        let photos = realmPhotos.objects(Photo.self)
        let max = photos.count + 12
        var cnt = 12
        for photo in photos {
            print("name: \(photo.url)")
            let url2 = "Data/C" + company_id + "/R" + photo.research_id + "/B" + photo.building_id + "/S" + photo.stage + "/D" + photo.division + "/"

            downloadFile(fileName: photo.url, path:url2)
            DispatchQueue.main.async {
                self.progressBar.setProgress((Float)(cnt/max), animated: false)
            }
            cnt += 1
        }
    }
    func downloadRoomMap(){
        print("DownloadRoomMap")
        let realmRoomMaps = try! Realm()
        
        let roomMaps = realmRoomMaps.objects(RoomMap.self)
        for roomMap in roomMaps {
            print("name: \(roomMap.filename)")
            let url = "Data/C" + company_id + "/R" + roomMap.research_id + "/B" + roomMap.building_id + "/S" + roomMap.stage + "/D"
            
            downloadFile(fileName: roomMap.filename, path:url)
        }
    }
    func downloadFile(fileName:String, path:String){
        self.DownloadCnt += 1
        //すでに写真が同期済み（端末に存在する）場合はダウンロードしない
        //調査内容が入れ替わる（新規）の場合は、以前の写真は消す
        let url = httpManager.getPhotoUrl() + path + fileName
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(fileName)
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(fileName)
        print("dounload=" + fileURL.path)
        //同じファイルがある場合はダウンロードしない
        if( FileManager.default.fileExists( atPath: fileURL.path ) ) {
            print("ファイルあり " + fileName)
            self.DownloadCnt = self.DownloadCnt - 1
            print("Count Down " + self.DownloadCnt.description)
        } else {
            Alamofire.download(url, to: destination).response { response in
                print(response)
                self.DownloadCnt = self.DownloadCnt - 1
                print("Count Down " + self.DownloadCnt.description)
                if response.error == nil, let photoPath = response.destinationURL?.path {
                    print("photoPath::::\(photoPath)")
                }
            }
        }
    }
    func nullCk(str:String)->String{
        var Ret = str
        if str.isEmpty {
            Ret = ""
        }
        return Ret
    }
}
