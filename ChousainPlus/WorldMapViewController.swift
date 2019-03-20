//
//  WorldMapViewController.swift
//  ChousainPlus
//
//  Created by ZeroSpace on 2019/03/08.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import RealmSwift
import SceneKit
import ARKit
class WorldMapViewController: UIViewController {

    @IBOutlet weak var imageRoom: UIImageView!
    @IBOutlet weak var sceneView: ARSCNView!
    var building_id = ""
    var stage = ""
    var room_name = ""
    var worldMapURL: URL = {
        do {
            return try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("worldMapURL")
        } catch {
            fatalError("Error getting world map URL from document directory.")
        }
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func loadWorldMap(_ sender: Any) {
        //カメラ位置データ
        let realmCameras = try! Realm()
        let cameraCollection = realmCameras.objects(CameraLocate.self) //building_id, dtage , room_nameでフィルター---------------
        //let max = cameraCollection.count
        for camera in cameraCollection {
            let x = Int(camera.m3x * 100) + Int(self.imageRoom.center.x)
            let y = Int(camera.m3z * 100) + Int(self.imageRoom.center.y)
            print( "x=" + x.description + ",y=" + y.description)
            
            let ar = UIImageView(image: UIImage(named: "arrow"))
            // UIImageViewの中心座標をタップされた位置に設定
            let pos = CGPoint(x: x, y: y)
            ar.center = pos
            
            // UIImageView(矢印)を追加
            self.view.addSubview(ar)
        }
        //写真位置データ
        let realmPhotos = try! Realm()
        let photoCollection = realmPhotos.objects(PhotoLocate.self)
        //let max = photoCollection.count
        for photo in photoCollection {
            let x = Int(photo.m3x * 100) + Int(self.imageRoom.center.x)
            let y = Int(photo.m3z * 100) + Int(self.imageRoom.center.y)
            print( "x=" + x.description + ",y=" + y.description)
            
            let ar = UIImageView(image: UIImage(named: "arrow_select"))
            // UIImageViewの中心座標をタップされた位置に設定
            let pos = CGPoint(x: x, y: y)
            ar.center = pos
            
            // UIImageView(矢印)を追加
            self.view.addSubview(ar)
        }
        //部屋マップデータ
        let realmRoomMap = try! Realm()
        let mapCollection = realmRoomMap.objects(RoomMap.self)
        //let max = cameraCollection.count
        for map in mapCollection {
            //物件id + ステージ　＋　部屋名　でファイル名生成-------------------------------------------------------
            let defaults = UserDefaults.standard
            building_id = defaults.string(forKey: "building_id")!
            stage = defaults.string(forKey: "stage")!
            let fileName = "M" + building_id + "_" + stage + "_" + self.room_name
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            worldMapURL = documentsURL.appendingPathComponent(fileName)
            
            LoadWorldMap()
            break;
        }
    }
    func LoadWorldMap() {
        guard let worldMapData = retrieveWorldMapData(from: worldMapURL),
            let worldMap = unarchive(worldMapData: worldMapData) else { return }
        //Anchor(PlaneAnchor)リスト
        for anchor in worldMap.anchors {
            let wall = anchor.transform.columns.3
            let x = Int(wall.x * 100) + Int(self.imageRoom.center.x)
            let y = Int(wall.z * 100) + Int(self.imageRoom.center.y)
            print( "x=" + x.description + ",y=" + y.description)
            
            let ar = UIImageView(image: UIImage(named: "index_folder_indicator"))
            // UIImageViewの中心座標をタップされた位置に設定
            let pos = CGPoint(x: x, y: y)
            ar.center = pos
            
            // UIImageView(矢印)を追加
            self.view.addSubview(ar)
        }

        
        /*
        worldMap.center
        worldMap.extent
        */
        
        //resetTrackingConfiguration(with: worldMap)
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
        
        //sceneView.session.run(configuration, options: options)
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
    @IBAction func finishView(_ sender: Any) {
        
        let next = storyboard!.instantiateViewController(withIdentifier: "photolist") as? PhotoController
        let _ = next?.view // ** hack code **
        self.present(next!,animated: true, completion: nil)
        
        //self.dismiss(animated: true, completion: nil)
    }
}
