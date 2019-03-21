//
//  CameraCloseupViewController.swift
//  ChousainPlus
//
//  Created by ZeroSpace on 2019/02/19.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation  //露光調整用
import RealmSwift

class CameraCloseupViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate{
    var research_id = ""
    var building_id = ""
    var stage = ""

    var wb_id :String = "1"
    var division:String = "1"
    var photo_num :Int = 0
    var photo_sub_num :Int = 0
    var room_name :String = ""
    var userid:String = ""
    var videoDevice: AVCaptureDevice?   //露光調整用
    
    let pointA = UIImageView(image: UIImage(named: "arrowb_4"))
    let pointB = UIImageView(image: UIImage(named: "arrowb_4"))
    var startPosition: SCNVector3!
    var centerPosition :SCNVector3!
    
    var bStart :Bool = false
    var stopAR :Bool = false
    var whiteBoardMake:Bool = false
    var bPrePhoto = false

    @IBOutlet weak var exposureSlider: UISlider!
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var lblRoomName: UILabel!
    @IBOutlet weak var lblWidth: UILabel!
    @IBOutlet weak var imageWhiteboard: UIImageView!
    @IBOutlet weak var btnPrePhoto: UIButton!
    @IBOutlet weak var imgPrePhoto: UIImageView!
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var viewPenItem: UIView!
    @IBOutlet weak var viewArrowItem: UIView!
    
    @IBOutlet weak var selectArrowPen: UISegmentedControl!
    @IBOutlet weak var btnPhotoSave: UIButton!

    var bARmode = true
    
    var status :Int  = 0
    class Arrow{
        var dir:Int = 0
        var image:UIImageView = UIImageView()
    }
    var arrows = [Arrow]()
    var selArrow:Int = 0
    var drawOn = true
    
    var drawView: DrawView! = nil
    
    var prePhotoUrl = ""
    var cameraPosition = simd_float4x4()
    var photoPosition = simd_float4x4()
    var worldMapURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("worldMapURL")
        } catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()
    var mapStart = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.session.delegate = self   //ARSessionDelegate

        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        //デバック用ワイヤーフレーム ワールド座標　表示
        //sceneView.debugOptions = [.showWireframe, .showWorldOrigin, .showFeaturePoints]
        //sceneView.debugOptions = [.showWireframe]
        
        // Set the scene to the view
        sceneView.scene = scene

        pointA.isHidden = true
        pointB.isHidden = true
        self.sceneView.addSubview(pointA)
        self.sceneView.addSubview(pointB)

        //露光調整用
        videoDevice = AVCaptureDevice.default(for: AVMediaType.video)
        exposureSlider.minimumValue = self.videoDevice?.minExposureTargetBias ?? 0.0
        exposureSlider.maximumValue = self.videoDevice?.maxExposureTargetBias ?? 0.0
        exposureSlider.value = self.videoDevice?.exposureTargetBias ?? 0.0

        if drawView == nil {
            //drawView = DrawView(frame: CGRect.init(0, 100, self.view.bounds.width, self.view.bounds.width))
            drawView = DrawView.init(frame: CGRect.init(x: 0, y: 102, width: sceneView.bounds.width, height: sceneView.bounds.height))
            drawView.isOpaque = false // 不透明を false
            drawView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0)
            drawView.isHidden = true
            self.view.addSubview(drawView)
        }
        
        viewPenItem.isHidden = true
        viewArrowItem.isHidden = true
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if stopAR == true {return}
        
        if photo_num == 0 {
            //写真番号セット
            let photoNumber = PhotoNumber.shared
            self.photo_num = photoNumber.photo_num[Int(division)! - 1]
        }
        //写真番号sub の検索
        if photo_sub_num == 0 {
            let defaults = UserDefaults.standard
            let research_id = defaults.string(forKey: "research_id")!
            let building_id = defaults.string(forKey: "building_id")!
            let stage = defaults.string(forKey: "stage")!
            let realmPhoto = try! Realm()
            let photoCollection = realmPhoto.objects(Photo.self).filter("research_id == %@ && building_id == %@ && stage == %@ && division == %@ && number == %@ && kind == %@", research_id, building_id, stage, self.division, self.photo_num.description, "2")
            if photoCollection.count == 0 {
                self.photo_sub_num = 1
            }else{
                self.photo_sub_num = Int(photoCollection[0].number_sub)! + 1
            }
        }


        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //平面検出
        configuration.planeDetection = [.horizontal, .vertical]
        
        
        //Harry Marker
        guard let referenceImage = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources",
                                                                    bundle: nil) else{
                                                                        return
        }
        configuration.detectionImages = referenceImage
        
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        lblRoomName.text = room_name

        lblStatus.text = "場所：" + room_name + " 写真番号：" + photo_num.description + ":" + photo_sub_num.description + " division=" + division + "白板：" + wb_id
        
        //物件id + ステージ　＋　部屋名　でファイル名生成-------------------------------------------------------
        let defaults = UserDefaults.standard
        research_id = defaults.string(forKey: "research_id")!
        building_id = defaults.string(forKey: "building_id")!
        stage = defaults.string(forKey: "stage")!
        let fileName = "M" + building_id + "_" + stage + "_" + self.room_name
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        worldMapURL = documentsURL.appendingPathComponent(fileName)
        
        /* 
        //WorldMap読み込み-----------------------------------------------RoomMapがある場合
        if mapStart == false{
            LoadWorldMap()
        }
         */
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    @IBAction func sliderChange(_ sender: Any) {
        changeExposureMode(exposureSlider)
    }
    //露出調整
    func changeExposureMode(_ control: UISlider) {
        
        do {
            try self.videoDevice!.lockForConfiguration()
            self.videoDevice!.setExposureTargetBias(control.value, completionHandler: nil)
            self.videoDevice!.unlockForConfiguration()
        } catch let error {
            NSLog("Could not lock device for configuration: \(error)")
        }
        
    }
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        /*
         //Plane検出
         guard let planeAnchor = anchor as? ARPlaneAnchor else {
         return
         }
         node.addChildNode(PlaneNode(anchor: planeAnchor))
         */
        
        //Huarry検出
        guard let imageAnchor = anchor as? ARImageAnchor else { return}
        let referenceImage = imageAnchor.referenceImage
        
        //新指揮したHurryをハイライトにする
        let plane = SCNPlane(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height)
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi/2        //90度回転
        planeNode.opacity = 1.0
        plane.firstMaterial?.diffuse.contents = UIImage(named:"Hurry6.jpg")
        node.geometry = plane
        node.addChildNode(planeNode)
        
        //planeNode.l
        
        /*
        //テキスト
        //let text = referenceImage.name!
        let nameNode = TextNode(str: "Hurry")
        nameNode.eulerAngles.x = -.pi/2
        //nameNode.eulerAngles.y = -.pi/2
        node.addChildNode(nameNode)
        */
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // アンカーが画像認識用か調べる
        if let imageAnchor = anchor as? ARImageAnchor {
            
            //　ジオメトリが設定されていなければ、ジオメトリを設定
            if(node.geometry == nil){
                let plane = SCNPlane()
                
                //　アンカーの大きさをジオメトリに反映させる
                plane.width = imageAnchor.referenceImage.physicalSize.width
                plane.height = imageAnchor.referenceImage.physicalSize.height
                
                // 今回は book2.jpg という画像を認識した画像の上に貼り付ける
                //plane.firstMaterial?.diffuse.contents = UIImage(named:"Hurry6.jpg")
                
                // 設置しているノードへジオメトリを渡し描画する
                node.geometry = plane
                node.eulerAngles.x = -.pi/2
                node.opacity = 0.0
            }
            
            //　位置の変更
            node.simdTransform = imageAnchor.transform
            //print("x=" + imageAnchor.transform.columns.3.x.description + ",y=" + imageAnchor.transform.columns.3.y.description + ",z=" + imageAnchor.transform.columns.3.z.description)
            //Word座標での中心位置
            let colim3 = node.worldPosition
            
            
            centerPosition = colim3
            
            //print("x=" + colim3.x.description + ",y=" + colim3.y.description + ",z=" + colim3.z.description)
            
            //カメラ座標に変換-----------------------------------------------
            guard let camera = sceneView.pointOfView else {return}
            
            let position = SCNVector3(colim3.x,colim3.y,colim3.z)
            //右上のポイント
            let CameraPosition = camera.convertPosition(position, from: nil)
            let leftTopPosition = SCNVector3Make(CameraPosition.x - 0.035, CameraPosition.y + 0.015, CameraPosition.z)
            
            //ワールド座標に戻す
            centerPosition = camera.convertPosition(leftTopPosition, to: nil)
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }

    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    @IBAction func tapSceneView(_ sender: UITapGestureRecognizer) {
        if self.bARmode == true {

            // HIt test
            let tapLoc = sender.location(in: sceneView) //タッチ位置
            let hitResult = sceneView.hitTest(tapLoc, types: .existingPlaneUsingExtent)
            //let hitResult = sceneView.hitTest(tapLoc, types: .existingPlaneUsingGeometry)
            //let hitResult = sceneView.hitTest(tapLoc, types: [.featurePoint])
            
            //最初＝手前のみを判定する
            guard let hitTResult = hitResult.first else {
                return
            }

            if bStart == false{
                bStart = true
                sceneView.session.pause()
                //シャッター音
                let soundIdRing:SystemSoundID = 1108  // new-mail.caf
                AudioServicesPlaySystemSound(soundIdRing)
                
                savePhoto()
            }
            //写真位置の保存
            let planeGeometry = SCNPlane(width: 0.2, height: 0.15)
            let paintingNode = SCNNode(geometry: planeGeometry)
            paintingNode.transform = SCNMatrix4((hitTResult.anchor?.transform)!)
            photoPosition = paintingNode.simdTransform

            //スクリーン座標系に変換
            let position = SCNVector3(centerPosition.x,centerPosition.y,centerPosition.z)
            let scrPosition = sceneView.projectPoint(position)
            DispatchQueue.main.async {
                var pos = CGPoint()
                pos.x = CGFloat(scrPosition.x)
                pos.y = CGFloat(scrPosition.y)
                self.pointA.center = pos
                self.pointA.isHidden = true
            }
            let endPosition = SCNVector3(hitTResult.worldTransform.columns.3.x, hitTResult.worldTransform.columns.3.y, hitTResult.worldTransform.columns.3.z)
            //print("end x=" + endPosition.x.description + ",y=" + endPosition.y.description + ",z=" + endPosition.z.description)
            let position2 = SCNVector3Make(endPosition.x - centerPosition.x, endPosition.y - centerPosition.y, endPosition.z - centerPosition.z)
            let distance = sqrt(position2.x*position2.x + position2.y*position2.y + position2.z*position2.z)
            print("距離=" + distance.description + " L=" + getWlength(length: distance).description)
            lblWidth.text = "W= " + getWlength(length: distance).description + "mm"
            
            //Wをセットする
            let photoNumber = PhotoNumber.shared
            let p_width = photoNumber.width
            if p_width < distance {
                photoNumber.width = distance
            }
            
            //スクリーン座標系に変換
            let position3 = SCNVector3(endPosition.x,endPosition.y,endPosition.z)
            let scrPosition3 = sceneView.projectPoint(position3)
            DispatchQueue.main.async {
                var pos = CGPoint()
                pos.x = CGFloat(scrPosition3.x)
                pos.y = CGFloat(scrPosition3.y)
                self.pointB.center = pos
                self.pointB.isHidden = false
            }
        }else{
            if bStart == false{
                bStart = true
                sceneView.session.pause()
                //シャッター音
                let soundIdRing:SystemSoundID = 1108  // new-mail.caf
                AudioServicesPlaySystemSound(soundIdRing)
                
                savePhoto()
            }
        }

        //カメラ位置の保存
        guard let currentFrame = sceneView.session.currentFrame else { return}
        let translation = matrix_identity_float4x4
        //translation.columns.3.z = -0.1
        print(currentFrame.camera.transform.debugDescription) //simd_float4x4
        self.cameraPosition = matrix_multiply(currentFrame.camera.transform, translation)
    }
    func savePhoto(){
        status = 1
        drawView.isHidden = false
        drawView.isUserInteractionEnabled = false
        viewArrowItem.isHidden = false
    }
    func getWlength(length:Float)->Float{
        
        //検出したARマーカーによってテーブルを変更する-------------------------------------------------
        
        var len:Float = 0.0
        if length < 0.009 {
            len = 0.1
        }else if length < 0.012{
            len = 0.15
        }else if length < 0.015{
            len = 0.2
        }else if length < 0.017{
            len = 0.25
        }else if length < 0.0203{
            len = 0.3
        }else if length < 0.0232{
            len = 0.35
        }else if length < 0.026{
            len = 0.4
        }else if length < 0.0286{
            len = 0.45
        }else if length < 0.0315{
            len = 0.5
        }else if length < 0.0342{
            len = 0.55
        }else if length < 0.0373{
            len = 0.6
        }else if length < 0.0397{
            len = 0.65
        }else if length < 0.0428{
            len = 0.7
        }else if length < 0.0455{
            len = 0.75
        }else if length < 0.0482{
            len = 0.8
        }else if length < 0.051{
            len = 0.85
        }else if length < 0.0538{
            len = 0.9
        }else if length < 0.0565{
            len = 0.95
        }else {
            len = 1.0
        }
        return len
    }
    
    //--------------------------------------------------------
    //オーバーレイ表示
    //--------------------------------------------------------
    @IBAction func viewPrePhoto(_ sender: Any) {
        
        if(self.prePhotoUrl != ""){
            if self.bPrePhoto == false {
                self.bPrePhoto = true
                self.imgPrePhoto.isHidden = false
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileURL = documentsURL.appendingPathComponent(self.prePhotoUrl)
                let path = fileURL.path
                self.imgPrePhoto.image = UIImage(contentsOfFile: path)
            }else{
                self.bPrePhoto = false
                self.imgPrePhoto.isHidden = true
            }
        }
    }
    @IBAction func takePhoto(_ sender: Any) {
        //if self.whiteBoardMake == false {return}
         //SnapShotを保存する
        let photo = sceneView.snapshot() as UIImage
        let photoManager = PhotoManager()
        let filename = photoManager.savePhoto(photo: photo, photo_mode: 3, division: division, photo_num: photo_num, photo_sub_num: photo_sub_num, room_name: room_name, userid: userid)
        
        let photoNumber = PhotoNumber.shared
        //let p_num = photoNumber.photo_num[Int(division)! - 1]
        
        //接写は白板データを保存しない-------------------------------
        
        //白板データセット
        let recordData = RecordData()
        recordData.saveWhiteboard(filename: filename)
        
        //矢印の合成
        var newImage = photo
        
        //マーカーの合成
        newImage = combainDrawImage(soureImage: newImage, combinImage: drawView.getCurrentImage())
        
        //白板画像の合成
        newImage = combainImage(soureImage: newImage, combinImage: imageWhiteboard.image!)
        
        //保存
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(filename)
        print("save="+fileURL.path)
        do {
            let jpgImage = newImage.jpegData(compressionQuality: 1.0)
            try jpgImage!.write(to: fileURL)
        } catch {
            //エラー処理
            print("Error")
        }
        
        
        //写真番号の更新
        //接写　sub番号の更新

        //PhotoControllerに戻る
        let controller = self.presentingViewController as? PhotoController
        let next = storyboard!.instantiateViewController(withIdentifier: "photolist") as? PhotoController
        let _ = next?.view // ** hack code **
        
        self.present(next!,animated: true, completion: {
            controller?.updateTableView()
        })
        
    }
    func combainImage(soureImage:UIImage, combinImage:UIImage)->UIImage{
        let newSize = CGSize(width:soureImage.size.width, height:soureImage.size.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, soureImage.scale)
        soureImage.draw(in: CGRect(x:0,y:0,width:newSize.width,height:newSize.height))
        //白板サイズ、位置指定
        combinImage.draw(in: CGRect(x:0,y:0,width:imageWhiteboard.image!.size.width/2,height:imageWhiteboard.image!.size.height/2),blendMode:CGBlendMode.normal, alpha:1.0)
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    func combainDrawImage(soureImage:UIImage, combinImage:UIImage)->UIImage{
        let newSize = CGSize(width:soureImage.size.width, height:soureImage.size.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, soureImage.scale)
        soureImage.draw(in: CGRect(x:0,y:0,width:newSize.width,height:newSize.height))
        //白板サイズ、位置指定
        combinImage.draw(in: CGRect(x:0,y:0,width:newSize.width,height:newSize.height),blendMode:CGBlendMode.normal, alpha:1.0)
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    @IBAction func viewWhiteBoard(_ sender: Any) {
        stopAR = true
        let next = storyboard!.instantiateViewController(withIdentifier: "whiteboard") as? WhiteBoardViewController
        let _ = next?.view // ** hack code **
        
        //next?.filename1 = photo.url
        next?.photo_mode = 3
        next?.wb_id = self.wb_id
        next?.room_name = self.room_name
        next?.photo_number = self.photo_num.description
        next?.W_str = self.lblWidth.text!

        self.present(next!,animated: true, completion: nil)
        
    }
    func viewWhiteBoard(room:String){
        self.room_name = room
        lblRoomName.text = room
        stopAR = true
        self.whiteBoardMake = true
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("whiteboard.jpg")
        let path = fileURL.path
        imageWhiteboard.image = UIImage(contentsOfFile: path)
        
        imageWhiteboard.isHidden = false;
    }
    @IBAction func finishView(_ sender: Any) {
        let next = storyboard!.instantiateViewController(withIdentifier: "photolist") as? PhotoController
        let _ = next?.view // ** hack code **
        
        self.present(next!,animated: true, completion: nil)
    }
    
    func saveWorldMap(){
        sceneView.session.getCurrentWorldMap { (worldMap, error) in
            guard let worldMap = worldMap else {
                return //self.lblStatus.text = "Error getting current world map."
            }
            
            do {
                print(worldMap.description)
                try self.archive(worldMap: worldMap)
                print("save WorldMap" + worldMap.description)
                
                let realmRoomMaps = try! Realm()
                let roomMap = RoomMap()
                roomMap.research_id = self.research_id
                roomMap.building_id = self.building_id
                roomMap.stage = self.stage
                roomMap.room_name = self.room_name
                roomMap.filename = "M" + self.building_id + "_" + self.stage + "_" + self.room_name
                try! realmRoomMaps.write {
                    realmRoomMaps.add(roomMap, update: true)
                }
            } catch {
                fatalError("Error saving world map: \(error.localizedDescription)")
            }
        }
    }
    func archive(worldMap: ARWorldMap) throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
        try data.write(to: self.worldMapURL, options: [.atomic])
    }
    func LoadWorldMap() {
        guard let worldMapData = retrieveWorldMapData(from: worldMapURL),
            let worldMap = unarchive(worldMapData: worldMapData) else { return }
        resetTrackingConfiguration(with: worldMap)
    }
    func resetTrackingConfiguration(with worldMap: ARWorldMap? = nil) {
        let scene = SCNScene()
        
        //再スタート
        sceneView.scene = scene
        /*
        let configuration = ARWorldTrackingConfiguration()
        //平面検出
        configuration.planeDetection = [.horizontal, .vertical]
        
        let options: ARSession.RunOptions = [.resetTracking, .removeExistingAnchors]
        if let worldMap = worldMap {
            configuration.initialWorldMap = worldMap
            //lblStatus.text = "Found saved world map."
        } else {
            //lblStatus.text = "Move camera around to map your surrounding space."
        }
        
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.session.run(configuration, options: options)
        */
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //平面検出
        configuration.planeDetection = [.horizontal, .vertical]
        
        
        //Harry Marker
        guard let referenceImage = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources",
                                                                    bundle: nil) else{
                                                                        return
        }
        configuration.detectionImages = referenceImage
        
        
        // Run the view's session
        sceneView.session.run(configuration)

    }
    func retrieveWorldMapData(from url: URL) -> Data? {
        do {
            return try Data(contentsOf: self.worldMapURL)
        } catch {
            //self.lblStatus.text = "Error retrieving world map data."
            return nil
        }
    }
    func unarchive(worldMapData data: Data) -> ARWorldMap? {
        guard let unarchievedObject = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data),
            let worldMap = unarchievedObject else { return nil }
        print("load WorldMap" + worldMap.description)
        return worldMap
    }
    @IBAction func selectArrowPenChange(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            drawView.isUserInteractionEnabled = false
            viewArrowItem.isHidden = false
            viewPenItem.isHidden = true
            self.drawOn = false
            break
        case 1:
            drawView.isUserInteractionEnabled = true
            viewArrowItem.isHidden = true
            viewPenItem.isHidden = false
            self.drawOn = true
            break
        default:
            break
        }
    }
    @IBAction func selectPenColor(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex{
        case 0:
            drawView.setColor(color: UIColor.red.cgColor)
            break
        case 1:
            drawView.setColor(color: UIColor.blue.cgColor)
            break
        case 2:
            drawView.setColor(color: UIColor.yellow.cgColor)
            break
        default:
            break
        }
    }
    @IBAction func selectPenSize(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex{
        case 0:
            drawView.setWidth(width: 3.0)
            break
        case 1:
            drawView.setWidth(width: 6.0)
            break
        case 2:
            drawView.setWidth(width: 12.0)
            break
        default:
            break
        }
    }
    @IBAction func clearDraw(_ sender: Any) {
        drawView.clearDraw()
    }
    @IBAction func switchAR(_ sender: UISwitch) {
        if sender.isOn {
            self.bARmode = true
        }else{
            self.bARmode = false
        }
    }
}
