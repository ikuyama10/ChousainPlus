//
//  UploadViewController.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/02/01.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import RealmSwift
import Alamofire

class UploadViewController: UIViewController {
    let httpManager = HttpManager()
    var mode = 1;
    
    var company_id = "0"
    var research_id = "0"
    var building_id = "0"
    var stage = "0"
    var division = "0"
    
    @IBOutlet weak var progressBar: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        progressBar.setProgress(0.0, animated: false)
        // Do any additional setup after loading the view.
    }
    
    @IBAction func finishVIew(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func uploadData(_ sender: Any) {
        let realmPhoto = try! Realm()
        let photoCollection = realmPhoto.objects(Photo.self)
    
        let defaults = UserDefaults.standard
        let userid = defaults.string(forKey: "userid")
        let keycode = defaults.string(forKey: "keycode")
        let research_id = defaults.string(forKey: "research_id")
        let building_id = defaults.string(forKey: "building_id")
        let max = photoCollection.count
        //Photo読み込み（新規更新分のみ送信）-------------------------------------------!!!!!!!!
        
        var cnt = 0
        for photo in photoCollection {
            progressBar.setProgress((Float)(cnt/max), animated: false)
            cnt += 1
            if(photo.status != "0"){
                print("upload name: \(photo.url)")
                //photo_owner --- userid  ------------------------------
                print(photo.userid)
                let parameters = "user_id=" + photo.userid
                    + "&research_id=" + research_id!
                    + "&building_id=" + building_id!
                    + "&stage=" + photo.stage
                    + "&division=" + photo.division
                    + "&kind=" + photo.kind
                    + "&room_name=" + photo.room_name
                    + "&filmed_at=" + photo.filmed_at
                    + "&no=" + photo.number
                    + "&subno=" + photo.number_sub
                    + "&label=" + photo.label
                    + "&url=" + photo.url
                    + "&wb_type=" + photo.wb_type
                    + "&wb_id=" + photo.wb_id
                    + "&item1=" + photo.item1
                    + "&item2=" + photo.item2
                    + "&item3=" + photo.item3
                    + "&item4=" + photo.item4
                    + "&item5=" + photo.item5
                    + "&item6=" + photo.item6
                    + "&item7=" + photo.item7
                    + "&item8=" + photo.item8
                    + "&item9=" + photo.item9
                    + "&item10=" + photo.item10
                    + "&keycode=" + keycode!
                self.httpPost(call: "setPhotos.php",parameter: parameters)
                
                //Upload Photo
                uploadPhoto(fileName: photo.url)
                
                //写真位置データ
                let realmPhotoLocate = try! Realm()
                let photoLocateCollection = realmPhotoLocate.objects(PhotoLocate.self)
                //let max = cameraCollection.count
                for photoLocate in photoLocateCollection {
                    
                    //print(photoLocate.debugDescription)
                    let parameters = "url=" + photoLocate.url
                        + "&number=" + photoLocate.number
                        + "&m0x=" + photoLocate.m0x.description
                        + "&m0y=" + photoLocate.m0y.description
                        + "&m0z=" + photoLocate.m0z.description
                        + "&m1x=" + photoLocate.m1x.description
                        + "&m1y=" + photoLocate.m1y.description
                        + "&m1z=" + photoLocate.m1z.description
                        + "&m2x=" + photoLocate.m2x.description
                        + "&m2y=" + photoLocate.m2y.description
                        + "&m2z=" + photoLocate.m2z.description
                        + "&m3x=" + photoLocate.m3x.description
                        + "&m3y=" + photoLocate.m3y.description
                        + "&m3z=" + photoLocate.m3z.description
                    self.httpPost(call: "setPhotoLocations.php",parameter: parameters)
                    
                }
                
                //カメラ位置データ
                let realmCameraLocate = try! Realm()
                let cameraLocateCollection = realmCameraLocate.objects(CameraLocate.self)
                //let max = cameraCollection.count
                for cameraLocate in cameraLocateCollection {
                    
                    //print(photoLocate.debugDescription)
                    let parameters = "url=" + cameraLocate.url
                        + "&number=" + cameraLocate.number
                        + "&m0x=" + cameraLocate.m0x.description
                        + "&m0y=" + cameraLocate.m0y.description
                        + "&m0z=" + cameraLocate.m0z.description
                        + "&m1x=" + cameraLocate.m1x.description
                        + "&m1y=" + cameraLocate.m1y.description
                        + "&m1z=" + cameraLocate.m1z.description
                        + "&m2x=" + cameraLocate.m2x.description
                        + "&m2y=" + cameraLocate.m2y.description
                        + "&m2z=" + cameraLocate.m2z.description
                        + "&m3x=" + cameraLocate.m3x.description
                        + "&m3y=" + cameraLocate.m3y.description
                        + "&m3z=" + cameraLocate.m3z.description
                    self.httpPost(call: "setCameraLocations.php",parameter: parameters)
                    
                }
                //----------------------------------------------------------------------------写真送信済みを確認してから更新
                //更新
                try! realmPhoto.write {
                    photo.status = "0"
                }
            
            }
            
            
        }
        
        //部屋データマップ
        let realmRoomMap = try! Realm()
        let mapCollection = realmRoomMap.objects(RoomMap.self)
        //let max = cameraCollection.count
        for map in mapCollection {
            //print(map.debugDescription)
            let parameters = "building_id=" + map.building_id
                + "&stage=" + map.stage
                + "&room_name=" + map.room_name
                + "&filename=" + map.filename
            
            self.httpPost(call: "setRoomMaps.php",parameter: parameters)
            
            uploadRoomMap(fileName: map.filename)
        }

        //self.dismiss(animated: true, completion: nil)
        let next = storyboard!.instantiateViewController(withIdentifier: "photolist") as? PhotoController
        let _ = next?.view // ** hack code **
        
        self.present(next!,animated: true, completion: nil)

    }
    func httpPost(call : String, parameter: String){
        let url = URL(string: httpManager.getUrl() + call)
        var request = URLRequest(url: url!)
        // POSTを指定
        request.httpMethod = "POST"
        // POSTするデータをBodyとして設定
        request.httpBody = parameter.data(using: .utf8)
        let session = URLSession.shared
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
        
    }
    func AnalsysResuls(data: Data){
        switch(mode){
        case 1:
            break;

        default: break
        }
    }
    func uploadPhoto(fileName : String){
        let sendPath = "Data/C" + self.company_id + "/R" + self.research_id + "/B" + self.building_id + "/S" + self.stage + "/D" + self.division
        let url = URL(string: httpManager.getUrl() + "upload2.php")
        //multipart/form-dataでデータを送信する方法
        Alamofire.upload(multipartFormData: { multipartFormData in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(fileName)

            //let fileNameWithoutExt = (fileName as NSString).deletingPathExtension
            //let ext = (fileName as NSString).pathExtension
            // UIImageからJPEGに変換してアップロード
            let path = fileURL.path
            let data = URL(fileURLWithPath: path)
            // 読み込んだJPEGファイルをそのままアップロード
            //let data = try! Data(contentsOf: Bundle.main.url(forResource: fileNameWithoutExt, withExtension: ext)!)
            multipartFormData.append(data , withName: "filename" , fileName: fileName , mimeType: "image/jpeg")
            multipartFormData.append(sendPath.data(using: String.Encoding.utf8)!, withName: "path")
            //print(multipartFormData)
        }, to: url!) { encodingResult in
            //encodingが成功するとこのハンドラが呼ばれる
            switch encodingResult {
            case.success(let upload, _ ,_):
                print(upload)
                //送信済みのフラグをセットする------------------------------------------------------
                let realmPhoto = try! Realm()
                let photoCollection = realmPhoto.objects(Photo.self)
                if photoCollection.count > 0{
                    
                }

                /*
                 .authenticate(user: "user", password: "password")
                 .uploadProgress(closure: { (progress) in
                 //進捗率の取得
                 print("Upload Progress: \(progress.fractionCompleted)")
                 })
                 */
            case.failure(let error):
                print(error)
            }
        }
    }
    func uploadRoomMap(fileName : String){
        let sendPath = "Data/C" + self.company_id + "/R" + self.research_id + "/B" + self.building_id + "/S" + self.stage
        let url = URL(string: httpManager.getUrl() + "uploadMap.php")
        //multipart/form-dataでデータを送信する方法
        Alamofire.upload(multipartFormData: { multipartFormData in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(fileName)
            
            //let fileNameWithoutExt = (fileName as NSString).deletingPathExtension
            //let ext = (fileName as NSString).pathExtension
            // UIImageからJPEGに変換してアップロード
            let path = fileURL.path
            let data = URL(fileURLWithPath: path)
            // 読み込んだJPEGファイルをそのままアップロード
            //let data = try! Data(contentsOf: Bundle.main.url(forResource: fileNameWithoutExt, withExtension: ext)!)
            multipartFormData.append(data , withName: "filename" , fileName: fileName , mimeType: "image/jpeg")
            multipartFormData.append(sendPath.data(using: String.Encoding.utf8)!, withName: "path")
            //print(multipartFormData)
        }, to: url!) { encodingResult in
            //encodingが成功するとこのハンドラが呼ばれる
            switch encodingResult {
            case.success(let upload, _ ,_):
                print(upload)
                /*
                 .authenticate(user: "user", password: "password")
                 .uploadProgress(closure: { (progress) in
                 //進捗率の取得
                 print("Upload Progress: \(progress.fractionCompleted)")
                 })
                 */
            case.failure(let error):
                print(error)
            }
        }
    }
}
