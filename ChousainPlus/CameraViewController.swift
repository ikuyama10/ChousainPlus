//
//  CameraViewController.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/01/28.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation  //露光調整用
import RealmSwift

class CameraViewController: UIViewController , ARSCNViewDelegate ,ARSessionDelegate{
    @IBOutlet weak var sceneView: ARSCNView!
    var research_id = ""
    var building_id = ""
    var stage = ""
    var stage_pre = ""

    var photo_mode = 1
    var grids = [Grid]()
    var photo_num : Int = 0
    var wb_id :String = "0"
    var division:String = "1"
    var room_name :String = ""
    var userid:String = ""
    var distance :CGFloat = 0.0
    var whiteBoardMake:Bool = false
 
    var mapStart = false
    var bPrePhoto = false

    var status :Int  = 0
    class Arrow{
        var dir:Int = 0
        var image:UIImageView = UIImageView()
    }
    var arrows = [Arrow]()
    var selArrow:Int = 0

    var bARmode = true
    var bViewWhiteBoard  = false
    
    @IBOutlet weak var btnWhiteboardEdit: UIButton!
    @IBOutlet weak var lblRoomName: UILabel!
    var videoDevice: AVCaptureDevice?   //露光調整用    
    @IBOutlet weak var exposureSlider: UISlider!

    @IBOutlet weak var modeTitle: UILabel!
    @IBOutlet weak var imageWhiteboard: UIImageView!
    @IBOutlet weak var measureLength: UILabel!
    @IBOutlet weak var btnViewMarker: UIButton!
    @IBOutlet weak var btnPrePhotoView: UIButton!
    @IBOutlet weak var imgPrePhoto: UIImageView!

    @IBOutlet weak var selectArrowPen: UISegmentedControl!
    @IBOutlet weak var viewPenItem: UIView!
    @IBOutlet weak var viewArrowItem: UIView!
    @IBOutlet weak var btnPhotoSave: UIButton!
    
    var drawView: DrawView! = nil

    var stopAR :Bool = false
    
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
    var worldMapURL_pre: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("worldMapURL")
        } catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()

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
        sceneView.debugOptions = [ .showFeaturePoints]
        
        // Set the scene to the view
        sceneView.scene = scene

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
        
        if(photo_mode == 1){
            modeTitle.text = "現況写真　" + getDivisionStr(div: Int(division)!)
            btnWhiteboardEdit.isHidden = true
            
        }else{
            modeTitle.text = "損傷写真　" + getDivisionStr(div: Int(division)!) + "写真番号：" + self.photo_num.description
            
        }
        if photo_num == 0 {
            //写真番号セット
            let photoNumber = PhotoNumber.shared
            if(self.photo_mode == 1){
                self.photo_num = photoNumber.photo_gen_num[Int(division)! - 1]
            }else{
                self.photo_num = photoNumber.photo_num[Int(division)! - 1]
            }
        }
        lblRoomName.text = room_name

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //平面検出
        configuration.planeDetection = [.horizontal, .vertical]
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        //物件id + ステージ　＋　部屋名　でファイル名生成-------------------------------------------------------
        let defaults = UserDefaults.standard
        research_id = defaults.string(forKey: "research_id")!
        building_id = defaults.string(forKey: "building_id")!
        stage = defaults.string(forKey: "stage")!
        let fileName = "M" + building_id + "_" + stage + "_" + self.room_name
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        worldMapURL = documentsURL.appendingPathComponent(fileName)

        //物件id + ステージ　＋　部屋名　でファイル名生成-------------------------------------------------------
        let fileName2 = "M" + building_id + "_" + stage_pre + "_" + self.room_name
        let documentsURL2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        worldMapURL_pre = documentsURL2.appendingPathComponent(fileName2)

        if prePhotoUrl == "" {
            btnViewMarker.isHidden = true
            btnPrePhotoView.isHidden = true
        }
        //WorldMap読み込み-----------------------------------------------RoomMapがある場合
        if stage_pre != ""{
            LoadWorldMap() //-------------------------------------------部屋のデータ 部屋名を指定する
        }
        //カメラノードの追加
        
        self.edWhiteBoard()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    @IBAction func sliderSet(_ sender: Any) {
        changeExposureMode(sender as! UISlider)
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
    func getDivisionStr(div : Int) ->String{
        var str :String = ""
        switch(div){
        case 1: str = "外部"
            break
        case 2: str = "内部"
            break
        case 3: str = "外構"
            break
        case 4: str = "傾斜"
            break
        case 5: str = "水準"
            break
        default:
            break
        }
        return str
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
        let next = storyboard!.instantiateViewController(withIdentifier: "closeup") as? CameraCloseupViewController
        let _ = next?.view // ** hack code **
        
        //next?.filename1 = photo.url
        next?.wb_id = self.wb_id
        next?.division = self.division
        next?.photo_num = self.photo_num
        next?.room_name = self.room_name
        
        self.present(next!,animated: true, completion: nil)
    }
    @IBAction func viewWhiteboard(_ sender: Any) {
        let next = storyboard!.instantiateViewController(withIdentifier: "whiteboard") as? WhiteBoardViewController
        let _ = next?.view // ** hack code **
        
        next?.wb_id = self.wb_id
        
        self.present(next!,animated: true, completion: nil)
    }
    @IBAction func finishView(_ sender: Any) {
        let next = storyboard!.instantiateViewController(withIdentifier: "photolist") as? PhotoController
        let _ = next?.view // ** hack code **
        
        self.present(next!,animated: true, completion: nil)
    }
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        /*
         //Plane検出
         guard let planeAnchor = anchor as? ARPlaneAnchor else {
         return
         }
         planeAnchor.transform
         node.addChildNode(PlaneNode(anchor: planeAnchor))
         */
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else { return }
        let grid = Grid(anchor: planeAnchor)
        self.grids.append(grid)
        node.addChildNode(grid)
    }
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        /*
         guard let planeAnchor = anchor as? ARPlaneAnchor else {
         return
         }
         guard let planeNode = node.childNodes.first as? PlaneNode else {
         return
         }
         planeNode.update(anchor: planeAnchor)
         */
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else { return }
        let grid = self.grids.filter { grid in
            return grid.anchor.identifier == planeAnchor.identifier
            }.first
        
        guard let foundGrid = grid else {
            return
        }
        
        foundGrid.update(anchor: planeAnchor)
    }
    
    //ARSession が更新されるたびに呼ばれる
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
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
        sceneView.session.pause()
        if self.bARmode == true {
            // HIt test
            var tapLoc = sender.location(in: sceneView) //タッチ位置
            //let hitTestResult = sceneView.hitTest(tapLoc, types: .existingPlaneUsingExtent)
            let hitTestResult = sceneView.hitTest(tapLoc, types: .existingPlane)
            
            //ARHitTestResult hitTest
            guard let hitTest = hitTestResult.first, let anchor = hitTest.anchor as? ARPlaneAnchor, let gridIndex = grids.index(where: { $0.anchor == anchor }) else {
                return
            }
            //addPainting(hitTest, grids[gridIndex])
        }
        if status  == 0 {
            /*
            self.imgPrePhoto.isHidden = true
            
            self.btnPhotoSave.setTitle("保存", for: .normal)
            
            status = 1
            drawView.isHidden = false
            drawView.isUserInteractionEnabled = false
            viewArrowItem.isHidden = false


            //シャッター音
            let soundIdRing:SystemSoundID = 1108  // new-mail.caf
            AudioServicesPlaySystemSound(soundIdRing)
            
            //カメラ位置の保存
            guard let currentFrame = sceneView.session.currentFrame else { return}
            var translation = matrix_identity_float4x4
            //translation.columns.3.z = -0.1
            print(currentFrame.camera.transform.debugDescription) //simd_float4x4
            self.cameraPosition = matrix_multiply(currentFrame.camera.transform, translation)
            */
            savePhotoPre()
            
            /*
            //箱ノードを0.1ｍ前方に置く カメラマーカー
            let boxNode = BoxNode(width:0.04, height:0.03)
            translation.columns.3.z = +0.002
            boxNode.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
            sceneView.scene.rootNode.addChildNode(boxNode)
            
            //写真番号
            let textNode2 = TextNode(str:"No." + self.photo_num.description)
            //translation.columns.3.z = -0.002
            //textNode2.simdTransform = matrix_multiply(currentFrame.camera.transform, translation)
            textNode2.position = SCNVector3(currentFrame.camera.transform.columns.3.x, currentFrame.camera.transform.columns.3.y, currentFrame.camera.transform.columns.3.z)
            sceneView.scene.rootNode.addChildNode(textNode2)
            */
        }else{
            var bTap = false
            let tapLoc = sender.location(in: sceneView) //タッチ位置
            
            //矢印のタップチェック
            let selArrowB = selArrow
            selArrow = 0
            for arr in arrows {
                print(arr.image.center.x.description + "," + tapLoc.x.description)
                print((arr.image.center.y - 108).description + "," + tapLoc.y.description)
                let ypos = arr.image.center.y - 108
                if arr.image.center.x > (tapLoc.x - 30) && arr.image.center.x < (tapLoc.x + 30) && ypos > (tapLoc.y - 30) && ypos < (tapLoc.y + 30) {
                    bTap = true
                    print("Tap")
                    dspArrow(index: selArrow, dir: arr.dir, select: true)
                    if selArrowB < arrows.count && selArrow != selArrowB{
                        dspArrow(index: selArrowB, dir: arrows[selArrowB].dir, select: false)
                    }
                    break
                }
                selArrow += 1
            }
            if bTap == false {
                //タップ位置に矢印をおく
                // UIImageView(矢印)作成
                let ar = UIImageView(image: UIImage(named: "arrow"))
                // UIImageViewの中心座標をタップされた位置に設定
                ar.center = sender.location(in: self.view)
                
                //矢印情報を保存
                let arrow = Arrow()
                arrow.image = ar
                self.arrows.append(arrow)
                dspArrow(index: self.selArrow, dir: 0, select: false)

                
                if arrows.count > 1 {
                    let index = arrows.count - 1
                    let length = getLength(startP: arrows[index - 1].image.center, endP: arrows[index].image.center)
                    
                    //lblLengthL.text = "長さ判定:" + (length / L).description + "cm"
                    print("length=" + length.description)
                }
                // UIImageView(矢印)を追加
                self.view.addSubview(ar)
                
                //きょりの再計算
                var index = 0
                var str = "L="
                for arr in arrows {
                    if index > 0 {
                        let length = getLength(startP: arrows[index - 1].image.center, endP: arr.image.center)
                        str = str + "L" + index.description + " " + Int(length*100).description + "cm "
                        print("length=" + length.description)
                    }
                    index += 1
                }
                print("end")
                measureLength.text = str
            }
            
        }

    }
    
    func savePhotoPre(){
        self.imgPrePhoto.isHidden = true
        
        self.btnPhotoSave.setTitle("保存", for: .normal)
        
        status = 1
        drawView.isHidden = false
        drawView.isUserInteractionEnabled = false
        viewArrowItem.isHidden = false
        
        
        //シャッター音
        let soundIdRing:SystemSoundID = 1108  // new-mail.caf
        AudioServicesPlaySystemSound(soundIdRing)
        
        //カメラ位置の保存
        guard let currentFrame = sceneView.session.currentFrame else { return}
        var translation = matrix_identity_float4x4
        //translation.columns.3.z = -0.1
        print(currentFrame.camera.transform.debugDescription) //simd_float4x4
        self.cameraPosition = matrix_multiply(currentFrame.camera.transform, translation)

    }
    
    func addPainting(_ hitResult: ARHitTestResult, _ grid: Grid) {
        //写真エリアマーカー
        let planeGeometry = SCNPlane(width: 0.4, height: 0.3)
        //let material = SCNMaterial()
        //material.diffuse.contents = UIImage(named: "photo_area")
        //planeGeometry.materials = [material]
        let paintingNode = SCNNode(geometry: planeGeometry)
        paintingNode.transform = SCNMatrix4(hitResult.anchor!.transform)
        paintingNode.eulerAngles = SCNVector3(paintingNode.eulerAngles.x + (-Float.pi / 2), paintingNode.eulerAngles.y, paintingNode.eulerAngles.z)
        //paintingNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        paintingNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, hitResult.worldTransform.columns.3.y, hitResult.worldTransform.columns.3.z)
        //paintingNode.position = SCNVector3(hitResult.worldTransform.columns.3.x, 0, hitResult.worldTransform.columns.3.z)
        //sceneView.scene.rootNode.addChildNode(paintingNode)
 
        photoPosition = paintingNode.simdTransform
        /*
        let pos = hitResult.worldTransform.columns.3  //PlaneAnchor上の位置

        //Textノード
        let textNode = TextNode(str:"No." + self.photo_num.description)
        textNode.position = SCNVector3(pos.x, pos.y, pos.z)
        //sceneView.scene.rootNode.addChildNode(textNode)
        */
        
        //Gridを消す
        grid.removeFromParentNode()
    }
    
    @IBAction func dragging(_ sender: UIPanGestureRecognizer) {
        let tapLoc = sender.location(in: self.view)
        switch sender.state.rawValue{
        case 1:
            //矢印のタップチェック
            let selArrowB = selArrow
            selArrow = 0
            for arr in arrows {
                if arr.image.center.x > (tapLoc.x - 30) && arr.image.center.x < (tapLoc.x + 30) && arr.image.center.y > (tapLoc.y - 30) && arr.image.center.y < (tapLoc.y + 30) {
                    arr.image.center = tapLoc
                    
                    dspArrow(index: selArrow, dir: arr.dir, select: true)
                    if selArrowB < arrows.count  && selArrow != selArrowB{
                        dspArrow(index: selArrowB, dir: arrows[selArrowB].dir, select: false)
                    }
                    break
                }
                selArrow += 1
            }
            print("start " + selArrow.description)
            break
        case 2:
            if selArrow < arrows.count {
                let ws = sceneView.center.y - sceneView.bounds.height / 2 + arrows[selArrow].image.bounds.height / 2
                if  tapLoc.x < (sceneView.bounds.maxX - arrows[selArrow].image.bounds.width / 2) && tapLoc.y > ws {
                    arrows[selArrow].image.center = tapLoc
                }
            }
            break
        case 3:
            //きょりの再計算
            var index = 0
            var str = "L="
            for arr in arrows {
                if index > 0 {
                    let length = getLength(startP: arrows[index - 1].image.center, endP: arr.image.center)
                    str = str + "L" + index.description + " " + Int(length*100).description + "cm "
                    print("length=" + length.description)
                }
                index += 1
            }
            print("end")
            measureLength.text = str
            break
        default:
            break
            
        }
    }
    func getLength(startP:CGPoint, endP:CGPoint)->Float{
        //let hitTestResult = sceneView.hitTest(tapLoc, types: .existingPlaneUsingExtent)
        let hitTestResultS = sceneView.hitTest(startP, types: .existingPlane)
        guard let hitTestS = hitTestResultS.first else {
            return 0.0
        }
        let hitTestResultE = sceneView.hitTest(endP, types: .existingPlane)
        guard let hitTestE = hitTestResultE.first else {
            return 0.0
        }
        let start = SCNVector3(hitTestS.worldTransform.columns.3.x,hitTestS.worldTransform.columns.3.y,hitTestS.worldTransform.columns.3.z)
        let end = SCNVector3(hitTestE.worldTransform.columns.3.x,hitTestE.worldTransform.columns.3.y,hitTestE.worldTransform.columns.3.z)
        let position = SCNVector3Make(start.x - end.x, start.y - end.y, start.z - end.z)
        let length = sqrt(position.x*position.x + position.y*position.y + position.z*position.z)
    
        return length
    }
    @IBAction func rotateArrow(_ sender: Any) {
        var dir = self.arrows[self.selArrow].dir + 1
        if dir >= 8 {
            dir = 0
        }
        self.arrows[self.selArrow].dir = dir
        dspArrow(index: self.selArrow, dir:dir, select: true)
    }
    @IBAction func deleteArrow(_ sender: Any) {
        arrows[selArrow].image.image = nil
        arrows.remove(at: selArrow)
        selArrow = 0
    }
    func dspArrow(index:Int,dir:Int, select:Bool){
        if index > 7 {return}
        if select == true{
            switch dir{
            case 0:
                arrows[index].image.image = UIImage(named: "arrow_select")
                break
            case 1:
                arrows[index].image.image = UIImage(named: "arrow_select_A")
                break
            case 2:
                arrows[index].image.image = UIImage(named: "arrow_select_2")
                break
            case 3:
                arrows[index].image.image = UIImage(named: "arrow_select_2A")
                break
            case 4:
                arrows[index].image.image = UIImage(named: "arrow_select_3")
                break
            case 5:
                arrows[index].image.image = UIImage(named: "arrow_select_3A")
                break
            case 6:
                arrows[index].image.image = UIImage(named: "arrow_select_4")
                break
            case 7:
                arrows[index].image.image = UIImage(named: "arrow_select_4A")
                break
            default:
                break
            }
        }else{
            switch dir{
            case 0:
                arrows[index].image.image = UIImage(named: "arrow")
                break
            case 1:
                arrows[index].image.image = UIImage(named: "arrow_A")
                break
            case 2:
                arrows[index].image.image = UIImage(named: "arrow_2")
                break
            case 3:
                arrows[index].image.image = UIImage(named: "arrow_2A")
                break
            case 4:
                arrows[index].image.image = UIImage(named: "arrow_3")
                break
            case 5:
                arrows[index].image.image = UIImage(named: "arrow_3A")
                break
            case 6:
                arrows[index].image.image = UIImage(named: "arrow_4")
                break
            case 7:
                arrows[index].image.image = UIImage(named: "arrow_4A")
                break
            default:
                break
            }
        }
    }
    @IBAction func editWhiteBoard(_ sender: Any) {
        self.edWhiteBoard()
    }
    func edWhiteBoard(){
        let next = storyboard!.instantiateViewController(withIdentifier: "whiteboard") as? WhiteBoardViewController
        let _ = next?.view // ** hack code **
        
        next?.wb_id = self.wb_id
        next?.room_name = self.room_name
        next?.photo_number = self.photo_num.description
        next?.L_str = self.measureLength.text!
        
        let photoNumber = PhotoNumber.shared
        next?.W_str = photoNumber.width.description
        
        stopAR = true
        whiteBoardMake = true
        self.present(next!,animated: true, completion: nil)
    }
    @IBAction func savePhoto(_ sender: Any) {
        if photo_mode != 1 {
            /*
            if whiteBoardMake == false {
                //白板情報を編集してください-----------------------------------------------------
                return
            }
            */
            self.savePhotoPre()
        }

        //SnapShotを保存する
        let photo = sceneView.snapshot() as UIImage
        let photoManager = PhotoManager()
        let filename = photoManager.savePhoto(photo: photo, photo_mode: photo_mode, division: division, photo_num: photo_num, photo_sub_num: 0, room_name: room_name, userid: userid)
        
        //白板データセット
        let recordData = RecordData()
        recordData.saveWhiteboard(filename: filename)
        
        //矢印の合成
        var newImage = photo
        for arr in arrows {
            
            newImage = combainArrowImage(soureImage: newImage, combinImage: arr.image.image!,posx: arr.image.center.x, posy: arr.image.center.y)
            
        }
        //マーカーの合成
        
        newImage = combainDrawImage(soureImage: newImage, combinImage: drawView.getCurrentImage())

        if photo_mode != 1 {
            //白板画像の合成
            newImage = combainImage(soureImage: newImage, combinImage: imageWhiteboard.image!)
        }
        
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
        
        //位置データ保存
        photoManager.saveWorldMap(url: filename, number: self.photo_num.description, position: self.cameraPosition)
        photoManager.savePhotoWorldMap(url: filename, number: self.photo_num.description ,position: self.photoPosition)
        saveWorldMap()
        
        //写真番号の更新
        if(photo_mode == 2){
            let photoNumber = PhotoNumber.shared
            photoNumber.photo_num[Int(self.division)! - 1] = photo_num + 1
        }else if(photo_mode == 3){
            //接写　sub番号の更新
            
        }else{
            let photoNumber = PhotoNumber.shared
            photoNumber.photo_gen_num[Int(self.division)! - 1] = photo_num + 1
        }

        //PhotoControllerに戻る
        let controller = self.presentingViewController as? PhotoController
        let next = storyboard!.instantiateViewController(withIdentifier: "photolist") as? PhotoController
        let _ = next?.view // ** hack code **
        
        self.present(next!,animated: true, completion: {
            controller?.updateRommName(room: self.room_name)
            controller?.updateTableView()
        })
        
    }

    func viewWhiteBoard(room:String){
        stopAR = true
        self.room_name = room
        lblRoomName.text = room
        //起動時に白板を表示した時は表示しない
        if bViewWhiteBoard == true{
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("whiteboard.jpg")
            let path = fileURL.path
            imageWhiteboard.image = UIImage(contentsOfFile: path)
            
            imageWhiteboard.isHidden = false;
        }else{
            //部屋名のセット--------------------------------------------
            
            bViewWhiteBoard = true
        }
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
    func combainArrowImage(soureImage:UIImage, combinImage:UIImage, posx:CGFloat, posy:CGFloat)->UIImage{
        let offsety = sceneView.center.y - sceneView.bounds.height / 2
        let newSize = CGSize(width:soureImage.size.width, height:soureImage.size.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, soureImage.scale)
        soureImage.draw(in: CGRect(x:0,y:0,width:newSize.width,height:newSize.height))
        //矢印サイズ、位置指定
        combinImage.draw(in: CGRect(x:posx*2 - combinImage.size.width, y:posy*2 - offsety*2 - combinImage.size.height, width:combinImage.size.width*2,height:combinImage.size.height*2),blendMode:CGBlendMode.normal, alpha:1.0)
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    @IBAction func loadPrePhoto(_ sender: Any) {
        //写真位置のロード
        let realmCameras = try! Realm()
        
        //以前の写真撮影位置を表示
        let cameraCollection = realmCameras.objects(CameraLocate.self).filter("url == %@", self.prePhotoUrl)
 
        //部屋内の写真---------------------------------------------
        //Photoで部屋内検索
        //見つかった写真のURLで位置データ検索
        //
        //let cameraCollection = realmCameras.objects(CameraLocate.self)    //部屋内-----------------------------
       
        for camera in cameraCollection {
            let boxNode = BoxNode(width:0.04, height:0.03)
            var translation = matrix_identity_float4x4
            translation.columns.0.x = camera.m0x
            translation.columns.0.y = camera.m0y
            translation.columns.0.z = camera.m0z
            translation.columns.0.w = 0.0
            translation.columns.1.x = camera.m1x
            translation.columns.1.y = camera.m1y
            translation.columns.1.z = camera.m1z
            translation.columns.1.w = 0.0
            translation.columns.2.x = camera.m2x
            translation.columns.2.y = camera.m2y
            translation.columns.2.z = camera.m2z
            translation.columns.2.w = 0.0
            translation.columns.3.x = camera.m3x
            translation.columns.3.y = camera.m3y
            translation.columns.3.z = camera.m3z
            translation.columns.3.w = 1.0
            
            print("load camera" + translation.debugDescription)
            boxNode.simdTransform = translation
            sceneView.scene.rootNode.addChildNode(boxNode)
        }
        
        //写真位置のロード
        let realmPhotos = try! Realm()
        let photoCollection = realmPhotos.objects(PhotoLocate.self).filter("url == %@", self.prePhotoUrl)
        //let maxP = photoCollection.count
        for photo in photoCollection {
            var translation = matrix_identity_float4x4
            translation.columns.0.x = photo.m0x
            translation.columns.0.y = photo.m0y
            translation.columns.0.z = photo.m0z
            translation.columns.0.w = 0.0
            translation.columns.1.x = photo.m1x
            translation.columns.1.y = photo.m1y
            translation.columns.1.z = photo.m1z
            translation.columns.1.w = 0.0
            translation.columns.2.x = photo.m2x
            translation.columns.2.y = photo.m2y
            translation.columns.2.z = photo.m2z
            translation.columns.2.w = 0.0
            translation.columns.3.x = photo.m3x
            translation.columns.3.y = photo.m3y
            translation.columns.3.z = photo.m3z
            translation.columns.3.w = 1.0
            
            print("load photo" + translation.debugDescription)

            //写真エリアマーカー
            let planeGeometry = SCNPlane(width: 0.4, height: 0.3)
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "photo_area")
            planeGeometry.materials = [material]
            let paintingNode = SCNNode(geometry: planeGeometry)
            
            paintingNode.simdTransform = translation
            
            paintingNode.eulerAngles = SCNVector3(paintingNode.eulerAngles.x, paintingNode.eulerAngles.y, paintingNode.eulerAngles.z)
            paintingNode.position = SCNVector3(translation.columns.3.x, translation.columns.3.y, translation.columns.3.z)
            sceneView.scene.rootNode.addChildNode(paintingNode)
            
            //Textノード
            let textNode = TextNode(str:"No." + photo.number)
            textNode.position = paintingNode.position //(pos.x, pos.y, pos.z)
            sceneView.scene.rootNode.addChildNode(textNode)
            
        }
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
        guard let worldMapData = retrieveWorldMapData(from: worldMapURL_pre),
            let worldMap = unarchive(worldMapData: worldMapData) else { return }
        resetTrackingConfiguration(with: worldMap)
    }
    func resetTrackingConfiguration(with worldMap: ARWorldMap? = nil) {
        let scene = SCNScene()
        
        //再スタート
        sceneView.scene = scene
        
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
            break
        case 1:
            drawView.isUserInteractionEnabled = true
            viewArrowItem.isHidden = true
            viewPenItem.isHidden = false
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
