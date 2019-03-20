//
//  PhotoController.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/01/27.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import RealmSwift
import LNZTreeView

class CustomUITableViewCell: UITableViewCell
{
    override func layoutSubviews() {
        super.layoutSubviews();
        
        guard var imageFrame = imageView?.frame else { return }
        
        let offset = CGFloat(indentationLevel) * indentationWidth
        imageFrame.origin.x += offset
        imageView?.frame = imageFrame
        
    }
}


class Node: NSObject, TreeNodeProtocol {
    var identifier: String
    var isExpandable: Bool {
        return children != nil
    }
    var photono: String
    
    var children: [Node]?
    
    init(withIdentifier identifier: String, photoNo:String, andChildren children: [Node]? = nil) {
        self.identifier = identifier
        self.children = children
        self.photono = photoNo
    }
}
class PhotoController: UIViewController,UIPickerViewDelegate, UIPickerViewDataSource{
    
    @IBOutlet weak var treeView: LNZTreeView!
    @IBOutlet weak var researchName: UILabel!
    @IBOutlet weak var buildingName: UILabel!
    @IBOutlet weak var roomName: UILabel!
    @IBOutlet weak var titleBar: UINavigationBar!
    @IBOutlet weak var stageName: UILabel!
    @IBOutlet weak var preStageName: UILabel!
    
    @IBOutlet weak var lblPreStage: UILabel!
    @IBOutlet weak var lblStage: UILabel!
    @IBOutlet weak var photoTableView: UITableView!
    @IBOutlet weak var btnSelectStage: UIButton!
    @IBOutlet weak var btnSelectRoom: UIButton!
    @IBOutlet weak var viewSelect: UIView!
    @IBOutlet weak var lblRoomName: UILabel!
    @IBOutlet weak var pickerRoomName: UIPickerView!
    @IBOutlet weak var btnSelectDivision: UISegmentedControl!
    
    var root = [Node]()
    var count = 0
    let realmPhoto = try! Realm()
    let realmPhotoList = try! Realm()

    var userid :String = ""
    var company_id :String = ""
    var research_id :String = ""
    var building_id :String = ""
    var room_name :String = ""

    var stage :String = "1"
    var pre_stage :String = "1"
    var division :String = "1"
    var wb_type :String = "1"
    var wb_id :String = "0"
    var room = [String]()
    var photo_num = [1,1,1,1,1]
    var photo_gen_num = [1,1,1,1,1]
    var photoList = [String:Int]()
    
    var mapStart = false
    var roomSelectMode = false
    var compos = [""]
    var room_nameSet :String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard
        userid = defaults.string(forKey: "userid")!
        company_id = defaults.string(forKey: "company_id")!
        research_id = defaults.string(forKey: "research_id")!
        building_id = defaults.string(forKey: "building_id")!
        stage = defaults.string(forKey: "stage")!
        
        let realmResearch = try! Realm()
        let researchCollection = realmResearch.objects(ResearchStage.self).filter("id == %@", self.research_id)
        researchName.text = "調査名 " + researchCollection[0].name

        let realmBuilding = try! Realm()
        let buildingCollection = realmBuilding.objects(Building.self).filter("id == %@", self.building_id)
        buildingName.text = "物件番号 " + buildingCollection[0].property_no //+ buildingCollection[0].owner_id

        let photoNumber = PhotoNumber.shared
        self.pre_stage = photoNumber.pre_stage.description

        //photoListテーブル作成
        makePhotoList()
        
        treeView.register(CustomUITableViewCell.self, forCellReuseIdentifier: "cell")
        treeView.tableViewRowAnimation = .right
        
        makeTree()

        //写真テーブル作成
        photoTableView.delegate = self
        photoTableView.dataSource = self
        photoTableView.rowHeight = 220 //UITableViewAutomaticDimension
        
        pickerRoomName.delegate = self
        pickerRoomName.dataSource = self


   }
    override func viewDidAppear(_ animated: Bool) {
        self.wb_id = getWhiteBoardId()
        //generateRandomNodes()
        treeView.resetTree()
        if(self.stage == "1"){
            //事前調査時
            self.lblPreStage.text = "今回の調査"
            self.lblStage.text = ""
            self.preStageName.text = "事前調査"
            self.stageName.text = ""
            self.btnSelectStage.isHidden = true
        }else{
            self.lblPreStage.text = "以前の調査"
            self.lblStage.text = "今回の調査"
            if self.pre_stage == "1" {
                self.preStageName.text = "事前調査"
            }else{
                self.preStageName.text = "ステージ" + self.pre_stage
            }
            self.stageName.text = "ステージ" + self.stage
            if(self.stage == "2"){
                self.btnSelectStage.isHidden = false
            }
        }
        makeRoomSelect(division: 1)
        //room_name初期値
        let photoNumber = PhotoNumber.shared
        if photoNumber.division != "" {
            self.division = photoNumber.division
            btnSelectDivision.selectedSegmentIndex = Int(self.division)! - 1
            self.selectDivision(index: Int(self.division)!)
        }
        room_name = photoNumber.room_name[Int(self.division)! - 1]
        lblRoomName.text = room_name
        
    }
    //--------------------------------------------------------
    //写真表示用テーブルデータ作成
    //--------------------------------------------------------
    func makePhotoList(){
        //全レコード削除
        let results = realmPhotoList.objects(PhotoNew.self) //-------------------------メモリ上　MAPで管理
        try! realmPhotoList.write {
            realmPhotoList.delete(results)
        }
        let sortProperties = [
            SortDescriptor(keyPath: "number", ascending: true),
            SortDescriptor(keyPath: "number_sub", ascending: true) ]
        if stage == "1" {
            let photoCollection = self.realmPhoto.objects(Photo.self).filter("research_id == %@ && building_id == %@ && stage == %@ && division == %@", self.research_id, self.building_id, self.stage, self.division).sorted(by:sortProperties)
            for photo in photoCollection {
                let photoNew = PhotoNew()
                photoNew.userid = photo.userid
                photoNew.stage = photo.stage
                photoNew.division = photo.division
                photoNew.kind = photo.kind
                photoNew.room_name = photo.room_name
                photoNew.number = photo.number
                photoNew.number_sub = photo.number_sub
                photoNew.label = photo.label
                photoNew.url1 = photo.url
                photoNew.url2 = ""
                photoNew.wb_id = photo.wb_id
                photoNew.status = photo.status

                try! realmPhotoList.write {
                    realmPhotoList.add(photoNew)
                }
                print("state=" + photo.stage + "photo number = " + photo.number)
            }
        }else{
            let photoCollection = self.realmPhoto.objects(Photo.self).filter("research_id == %@ && building_id == %@ && stage == %@ && division == %@", self.research_id, self.building_id, self.pre_stage, self.division).sorted(by:sortProperties)
            for photo in photoCollection {
                let photoNew = PhotoNew()
                photoNew.userid = photo.userid
                photoNew.stage = self.stage
                photoNew.division = photo.division
                photoNew.kind = photo.kind
                photoNew.room_name = photo.room_name
                photoNew.number = photo.number
                photoNew.number_sub = photo.number_sub
                photoNew.label = photo.label
                photoNew.url1 = photo.url
                photoNew.url2 = ""
                photoNew.wb_id = photo.wb_id
                photoNew.status = photo.status
                
                print("state=" + photo.stage + "photo number = " + photo.number)
                
                let photoCollection2 = self.realmPhoto.objects(Photo.self).filter("userid == %@ && research_id == %@ && building_id == %@ && stage == %@ && division == %@ && room_name == %@ && kind == %@ && number == %@ && number_sub == %@", photo.userid, self.research_id, self.building_id, self.stage, self.division, photo.room_name, photo.kind, photo.number, photo.number_sub)
                //let photoCollection2 = self.realmPhoto.objects(Photo.self).filter("research_id == %@ && building_id == %@ && stage == %@ && division == %@ && room_name == %@ && kind == %@ && number == %@ && number_sub == %@", self.research_id, self.building_id, self.stage, self.division, photo.room_name, photo.kind, photo.number, photo.number_sub)
                if photoCollection2.count > 0 {
                    let photoNew2 = photoCollection2[0]
                    photoNew.url2 = photoNew2.url
                    print ("全ステージの写真発見 userid=" + photo.userid + ",userid2=" + photoNew2.userid)
                }
                try! realmPhotoList.write {
                    realmPhotoList.add(photoNew)
                }
            }
            //今回のステージで追加した写真を追加------------------------------------------------------------------------
            
            let photoCollection4 = self.realmPhoto.objects(Photo.self).filter("research_id == %@ && building_id == %@ && stage == %@ && division == %@", self.research_id, self.building_id, self.stage, self.division)
            for photo in photoCollection4 {
                let photoNew = PhotoNew()
                photoNew.userid = photo.userid
                photoNew.stage = photo.stage
                photoNew.division = photo.division
                photoNew.kind = photo.kind
                photoNew.room_name = photo.room_name
                photoNew.number = photo.number
                photoNew.number_sub = photo.number_sub
                photoNew.label = photo.label
                photoNew.url1 = ""
                photoNew.url2 = photo.url
                photoNew.wb_id = photo.wb_id
                photoNew.status = photo.status
                
                let photoCollection4 = self.realmPhoto.objects(Photo.self).filter("userid == %@ && research_id == %@ && building_id == %@ && stage == %@ && division == %@ && room_name == %@ && kind == %@ && number == %@ && number_sub == %@", photo.userid, self.research_id, self.building_id, self.pre_stage, self.division, photo.room_name, photo.kind, photo.number, photo.number_sub)
                if photoCollection4.count == 0 {
                    print("3state=" + photo.stage + "photo number = " + photo.number)
                    //前回調査がない場合、新規撮影分を登録
                    try! realmPhotoList.write {
                        realmPhotoList.add(photoNew)
                    }
                }
            }
 
        }
    }
    func makeTree(){
        //写真リストから部屋名のリストを抽出
        let photoCollection = realmPhotoList.objects(PhotoNew.self).filter("division == %@", self.division)
        //root = [Node(withIdentifier: "", photoNo: "現況")]
        room.removeAll()
        room.append("現況")
        root.append(Node(withIdentifier: "現況",photoNo: "現況"))
        for photo in photoCollection {
            if(photo.room_name != ""){
                let index = room.index(of:photo.room_name)
                if(index == nil){
                    room.append(photo.room_name)
                    root.append(Node(withIdentifier: photo.room_name,photoNo: photo.room_name))
                }
            }
            
            //写真番号の初期値を探す
            let num = Int(photo.number)!
            if(photo.kind == "0"){
                if(self.photo_gen_num[Int(photo.division)! - 1] <= num){
                    self.photo_gen_num[Int(photo.division)! - 1] = num + 1
                }
            }else if(photo.kind == "1"){
                if(self.photo_num[Int(photo.division)! - 1] <= num){
                    self.photo_num[Int(photo.division)! - 1] = num + 1
                }
            }
        }
        let photoNumber = PhotoNumber.shared
        for i in 0..<5 {
            photoNumber.photo_num[i] = self.photo_num[i]
            photoNumber.photo_gen_num[i] = self.photo_gen_num[i]
        }
        
        for rm in room {
            var photo = [String]()
            var photoN = [Node]()
            print(rm)
            let photoCollection = realmPhotoList.objects(PhotoNew.self).filter("division == %@ && room_name == %@ && kind == %@", self.division, rm, "1")
            let index = room.index(of:rm)
            if(index != nil){
                for ph in photoCollection {
                    print(ph.number)
                    //room[index]
                    photo.append(ph.number)
                    photoN.append(Node(withIdentifier: ph.number,photoNo: ph.number))
                }
                root[index!].children = photoN
            }
        }
        //Node(withIdentifier: "部屋" + String(count),photoNo: "部屋" + String(count))
        // phots 部屋名　ー　写真番号　でインデックス化
        //部屋名　＞　現況写真　＞　損傷写真　＞　接写写真　でツリー制作
        /*
         root = generateRoomNodes(2)
         
         let children = generateNodes(2)
         root[0].children = children
         
         let children1 = generateNodes(4)
         root[1].children = children1
         */
        
        
    }
    func updateTableView() {
        
        // 各セルの内容の要素を作る処理(今回は、データベースから値を読み込み配列に格納)
        // 再描画
        //画面のリロード
        //loadView()
        //viewDidLoad()
        photoTableView.reloadData()
        //makeTree()
    }
    //-----------------------------------------------------------
    //Photo Table1関連
    func numberOfSections(in tableView: UITableView) -> Int {
        //現況　損傷で２セクションにする--------------------------
        photoList.removeAll()
        return 2
    }
    /*
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        let photoCollection = realmPhoto.objects(Photo.self)
        let rcount = photoCollection.count
        return  rcount
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoCell") as! PhotoTableCell

        let photoCollection = realmPhoto.objects(Photo.self)
        let photo = photoCollection[indexPath.row]
        
        /*
        //読み込み
        if let obj = photoCollection.last {
            let filename = obj.photo_url
            print(filename)
        }
        print(photoCollection)
        */
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(photo.photo_url)
        let path = fileURL.path
        print("view=" + path)
        let image = UIImage(contentsOfFile: path)
        cell.Photo2.image = image
        cell.photo_number.text = photo.photo_number
        return cell
        
    }
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 220.0
    }
    */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*
        //performSegue(withIdentifier: "editphoto", sender: nil)
        let next = storyboard!.instantiateViewController(withIdentifier: "photoView") as? PhotoViewController
        let _ = next?.view // ** hack code **
        
        let section = (indexPath as NSIndexPath).section
        if(section == 0){
            let photoCollection = self.realmPhoto.objects(Photo.self).filter("research_id == %@ && building_id == %@ && stage == %@ && division == %@ && kind == %@", self.research_id, self.building_id, self.stage, self.division,"0")
            let photo = photoCollection[indexPath.row]
            next?.filename1 = photo.url
            next?.wb_id = photo.wb_id
            
            next?.division = self.division
            next?.photo_num = Int(photo.number)! //-------------------------------------- sub
            next?.photo_mode = Int(photo.kind)! + 1
            next?.room_name = photo.room_name
        }else{
            let photoCollection = self.realmPhoto.objects(Photo.self).filter("research_id == %@ && building_id == %@ && stage == %@ && division == %@ && kind != %@", self.research_id, self.building_id, self.stage, self.division,"0")
            let photo = photoCollection[indexPath.row]
            next?.filename1 = photo.url
            next?.wb_id = photo.wb_id
            
            next?.division = self.division
            next?.photo_num = Int(photo.number)! //-------------------------------------- sub
            next?.photo_mode = Int(photo.kind)! + 1
            let room = photo.room_name
            next?.room_name = photo.room_name
        }
        self.present(next!,animated: true, completion: nil)
        */
    }
    //----------------------------------------------------------
    //Tree
    func generateRandomNodes() {
        //let depth = 3
        //let rootSize = 30
        
        //var root: [Node]!
        /*
        var lastLevelNodes: [Node]?
        for i in 0..<depth {
            guard let lastNodes = lastLevelNodes else {
                root = generateNodes(rootSize, depthLevel: i)
                lastLevelNodes = root
                continue
            }
            
            var thisDepthLevelNodes = [Node]()
            for node in lastNodes {
                guard arc4random()%2 == 1 else { continue }
                let childrenNumber = Int(arc4random()%20 + 1)
                let children = generateNodes(childrenNumber, depthLevel: i)
                node.children = children
                thisDepthLevelNodes += children
            }
            
            lastLevelNodes = thisDepthLevelNodes
        }
        */
        count = 0
        //部屋リスト（親）
        //root = generateRoomNodes(room.count, depthLevel: 1)
        root = generateRoomNodes(2)

        let children = generateNodes(2)
        root[0].children = children
        
        let children1 = generateNodes(4)
        root[1].children = children1

        //self.root = root
    }
    func generateRoomNodes(_ numberOfNodes: Int) -> [Node] {
        let nodes = Array(0..<numberOfNodes).map { i -> Node in
            count += 1
            return Node(withIdentifier: "部屋" + String(count),photoNo: "部屋" + String(count))
        }
        
        return nodes
    }
    func generateNodes(_ numberOfNodes: Int) -> [Node] {
        let nodes = Array(0..<numberOfNodes).map { i -> Node in
            count += 1
            return Node(withIdentifier: "\(arc4random()%UInt32.max)",photoNo: String(count))
        }
        
        return nodes
    }
    func generatePhotoNodes(data: [String]) -> [Node] {
        let nodes = Array(0..<data.count).map { i -> Node in
            count += 1
            return Node(withIdentifier: data[count],photoNo: String(count))
        }
        
        return nodes
    }

    
    //----------------------------------------------------------------------------------
    //Divisionの選択
    //----------------------------------------------------------------------------------
    @IBAction func SelectDIv(_ sender: UISegmentedControl) {
        let index :Int = sender.selectedSegmentIndex + 1
        self.selectDivision(index: index)
    }
    func selectDivision(index:Int){
        self.division = index.description
        self.wb_type = index.description//.selectedSegmentIndex.description
        
        self.wb_id = getWhiteBoardId()
        
        //makeRoomSelect(division: 1)
        
        let photoNumber = PhotoNumber.shared
        photoNumber.division = self.division
        
        makePhotoList()
        makeTree()
        makeRoomSelect(division: index)
        
        photoTableView.reloadData()
    }
    func getWhiteBoardId() -> String {
        let realmWhiteBoard = try! Realm()
        let wbCollection = realmWhiteBoard.objects(WhiteBoardMaster.self).filter("wb_type == %@", self.wb_type)
        let whiteBoard = wbCollection.last
        return whiteBoard!.wbid
    }
    @IBAction func finishView(_ sender: Any) {
        let next = storyboard!.instantiateViewController(withIdentifier: "ReserchList") as? ResearchListController
        let _ = next?.view // ** hack code **
        
        self.present(next!,animated: true, completion: nil)
    }
    @IBAction func viewUpload(_ sender: Any) {
        let next = storyboard!.instantiateViewController(withIdentifier: "upload") as? UploadViewController
        let _ = next?.view // ** hack code **
        
        next?.research_id = self.research_id
        next?.company_id = self.company_id
        next?.building_id = self.building_id
        next?.division = self.division
        next?.stage = self.stage
        
        self.present(next!,animated: true, completion: nil)
        
    }
    //--------------------------------------------------------
    //現況写真撮影
    //--------------------------------------------------------
    @IBAction func btnPhoto(_ sender: Any) {
        //現況写真
        let next = storyboard!.instantiateViewController(withIdentifier: "camera") as? CameraViewController
        let _ = next?.view // ** hack code **
        
        next?.photo_mode = 1
        next?.wb_id = getWhiteBoardId()
        next?.division = self.division
        next?.photo_num = 0
        next?.mapStart = self.mapStart
        mapStart = true
        self.present(next!,animated: true, completion: nil)
        
        
    }
    //--------------------------------------------------------
    //損傷写真撮影
    //--------------------------------------------------------
    @IBAction func btnDetailPhoto(_ sender: Any) {
        //損傷写真
        let next = storyboard!.instantiateViewController(withIdentifier: "camera") as? CameraViewController
        let _ = next?.view // ** hack code **
        
        next?.photo_mode = 2
        next?.wb_id = getWhiteBoardId()
        next?.division = self.division
        next?.photo_num = self.photo_num[Int(self.division)! - 1]
        next?.mapStart = self.mapStart
        next?.room_name = room_name
        mapStart = true

        self.present(next!,animated: true, completion: nil)
    }
    @IBAction func btnCploseupPhoto(_ sender: Any) {
        let next = storyboard!.instantiateViewController(withIdentifier: "closeup") as? CameraCloseupViewController
        let _ = next?.view // ** hack code **
        
        next?.wb_id = getWhiteBoardId()
        next?.division = self.division
        next?.photo_num = 0
        next?.room_name = room_name
        next?.photo_sub_num = 0
        next?.userid = userid
        
        self.present(next!,animated: true, completion: nil)
    }
    @IBAction func returnTo(segue: UIStoryboardSegue){
        //画面のリロード
        //loadView()
        //viewDidLoad()
        photoTableView.reloadData()
        
    }
    @IBAction func SelectStage(_ sender: Any) {
        let alert = UIAlertController(title: "以前の調査回写真の選択", message: "表示する調査回を選択してください", preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(title:"事前調査", style: .default, handler: {(action) ->Void in self.select(1)})
        )
        let max = Int(stage)!
        if max >= 2{
            for i in 2..<max{
                //stage_nameをつかう----------------------------------------
                
                alert.addAction(
                    UIAlertAction(title:i.description + "回目調査", style: .default, handler: {(action) ->Void in self.select(i)})
                )
            }
        }
        self.present(alert, animated: true, completion:{})
    }
    func select(_ sel:Int){
        self.pre_stage = sel.description
        if sel == 1 {
            preStageName.text = "事前調査"
        }else{
            preStageName.text = sel.description + "回目調査"
        }
        //写真リストの再描画-----------------------------------------------------
        let photoNumber = PhotoNumber.shared
        photoNumber.pre_stage = sel

        makePhotoList()
        makeTree()
        
        photoTableView.reloadData()

    }
    //--------------------------------------------------------
    //テーブル右側タッチ
    //--------------------------------------------------------
    @IBAction func takeAfterPhoto(_ sender: Any) {
        let botton = sender as! UIButton
        let cell = botton.superview?.superview as! PhotoTableCell
        let row = photoTableView.indexPath(for: cell)?.row
        let section = photoTableView.indexPath(for: cell)?.section

        print((section?.description)! + ":" + (row?.description)!)
        
        if self.stage != "1" {
            let ret = takePhoto(section: section!, row: row!)
            if ret == true {
                showPhoto(section: section!, row: row! ,st: 2)
            }
        }
    }
    
    //--------------------------------------------------------
    //テーブル左側タッチ
    //--------------------------------------------------------
    @IBAction func takeBeforePhoto(_ sender: Any) {
        let botton = sender as! UIButton
        let cell = botton.superview?.superview as! PhotoTableCell
        let row = photoTableView.indexPath(for: cell)?.row
        let section = photoTableView.indexPath(for: cell)?.section
        
        print((section?.description)! + ":" + (row?.description)!)
        //写真ありの場合　写真詳細画面
        showPhoto(section: section!, row: row!,st :1)
    }
    //--------------------------------------------------------
    //写真表示
    //--------------------------------------------------------
    func showPhoto(section :Int, row:Int, st:Int){
        //performSegue(withIdentifier: "editphoto", sender: nil)
        let next = storyboard!.instantiateViewController(withIdentifier: "photoView") as? PhotoViewController
        let _ = next?.view // ** hack code **
        if(section == 0){
            let photoCollection = self.realmPhotoList.objects(PhotoNew.self).filter("division == %@ && kind == %@", self.division,"0")
            let photo = photoCollection[row]
            if st == 1 {
                next?.filename1 = photo.url1
            }else{
                next?.filename1 = photo.url1
                next?.filename2 = photo.url2
            }
            next?.wb_id = photo.wb_id
            
            next?.division = self.division
            next?.photo_num = Int(photo.number)! //-------------------------------------- sub
            next?.photo_mode = Int(photo.kind)! + 1
            next?.room_name = photo.room_name
            next?.stage = photo.stage
            next?.dsp = st
        }else{
            let photoCollection = self.realmPhotoList.objects(PhotoNew.self).filter("division == %@ && kind != %@", self.division,"0")
            let photo = photoCollection[row]
            if st == 1 {
                next?.filename1 = photo.url1
            }else{
                next?.filename1 = photo.url1
                next?.filename2 = photo.url2
            }
            next?.wb_id = photo.wb_id
            print(photo.description)

            next?.division = self.division
            next?.photo_num = Int(photo.number)! //-------------------------------------- sub
            next?.photo_mode = Int(photo.kind)! + 1
            next?.room_name = photo.room_name
            next?.stage = photo.stage
            next?.dsp = st
        }
        self.present(next!,animated: true, completion: nil)

    }
    //--------------------------------------------------------
    //写真撮影
    //--------------------------------------------------------
    func takePhoto(section :Int, row:Int)->Bool{
        var bRet = false;
        var photo_num :Int = 0
        var photo_sub_num :Int = 0
        var room_name = ""
        var userid:String = ""
        var kind = ""
        var url :String = ""
        var url_pre :String = ""

        if(section == 0){
            let photoCollection = self.realmPhotoList.objects(PhotoNew.self).filter("division == %@ && kind == %@", self.division,"0")
            let photo = photoCollection[row]
            photo_num = Int(photo.number)!
            photo_sub_num = Int(photo.number_sub)!
            room_name = photo.room_name
            kind = photo.kind
            url = photo.url2
            url_pre = photo.url1
            userid = photo.userid
        }else{
            let photoCollection = self.realmPhotoList.objects(PhotoNew.self).filter("division == %@ && kind != %@", self.division,"0")
            let photo = photoCollection[row]
            photo_num = Int(photo.number)!
            photo_sub_num = Int(photo.number_sub)!
            room_name = photo.room_name
            kind = photo.kind
            url = photo.url2
            url_pre = photo.url1
            userid = photo.userid
        }
        if url == "" {
            //接写モードの場合
            if(kind == "2"){
                let next = storyboard!.instantiateViewController(withIdentifier: "closeup") as? CameraCloseupViewController
                let _ = next?.view // ** hack code **
                
                next?.wb_id = getWhiteBoardId()
                next?.division = self.division
                next?.photo_num = photo_num
                next?.room_name = room_name
                next?.photo_sub_num = photo_sub_num
                next?.userid = userid
                next?.prePhotoUrl = url_pre

                self.present(next!,animated: true, completion: nil)
            }else{
                let next = storyboard!.instantiateViewController(withIdentifier: "camera") as? CameraViewController
                let _ = next?.view // ** hack code **
                if section == 0 {
                    next?.photo_mode = 1
                }else{
                    next?.photo_mode = 2
                }
                next?.wb_id = getWhiteBoardId()
                next?.division = self.division
                next?.photo_num = photo_num
                //label ---------------------------------------------------------------------------
                next?.room_name = room_name
                next?.userid = userid
                next?.mapStart = self.mapStart
                next?.prePhotoUrl = url_pre
                next?.stage_pre = pre_stage
                mapStart = true

                self.present(next!,animated: true, completion: nil)
            }
        }else{
            bRet = true
        }
        return bRet
    }
    @IBAction func takeCloseupPhoto(_ sender: Any) {
        print("接写")
        let botton = sender as! UIButton
        let cell = botton.superview?.superview as! PhotoTableCell
        let row = photoTableView.indexPath(for: cell)?.row
        let section = photoTableView.indexPath(for: cell)?.section
        
        print((section?.description)! + ":" + (row?.description)!)
        
        let photoCollection = self.realmPhotoList.objects(PhotoNew.self).filter("division == %@ && kind != %@", self.division,"0")
        let photo = photoCollection[row!]
        let photo_num = Int(photo.number)!
        let photo_sub_num = Int(photo.number_sub)!
        room_name = photo.room_name
        //let kind = photo.kind
        //let url = photo.url2
        let url_pre = photo.url1
        userid = photo.userid
        
        let next = storyboard!.instantiateViewController(withIdentifier: "closeup") as? CameraCloseupViewController
        let _ = next?.view // ** hack code **
        
        next?.wb_id = getWhiteBoardId()
        next?.division = self.division
        next?.photo_num = photo_num
        next?.room_name = room_name
        next?.photo_sub_num = photo_sub_num
        next?.userid = userid
        next?.prePhotoUrl = url_pre
        
        self.present(next!,animated: true, completion: nil)
        
    }
    //--------------------------------------------------------
    //部屋の選択
    //--------------------------------------------------------
    @IBAction func roomSelect(_ sender: Any) {
        if roomSelectMode == false {
            roomSelectMode = true
            viewSelect.isHidden = false
            btnSelectRoom.setTitle("選択", for:.normal)
            self.mapStart = false
        }else{
            roomSelectMode = false
            viewSelect.isHidden = true
            btnSelectRoom.setTitle("変更", for:.normal)
            lblRoomName.text = room_nameSet
            room_name = room_nameSet
            let photoNumber = PhotoNumber.shared
            photoNumber.room_name[Int(self.division)! - 1] = room_name
        }
    }
    //--------------------------------------------------------------------
    //Room選択
    //--------------------------------------------------------------------
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 150
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return compos[row]
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return compos.count
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        room_nameSet = compos[row]
    }
    func makeRoomSelect(division:Int){
        //PickerView
        compos.removeAll()
        let realmDictionary = try! Realm()
        let DictionaryCollection = realmDictionary.objects(Dictionary.self).filter("wbid == %@ && item_id == %@", self.wb_id, "1")
        
        if(DictionaryCollection.count > 0){
            for dictionary in DictionaryCollection {
                compos.append(dictionary.item)
            }
            let photoNumber = PhotoNumber.shared
            if photoNumber.room_name[division - 1] == "" {
                lblRoomName.text = compos[0]
                room_name = compos[0]
                photoNumber.room_name[division - 1] = compos[0]

            }else{
                lblRoomName.text = photoNumber.room_name[division - 1]
                room_name = photoNumber.room_name[division - 1]
            }

            pickerRoomName.reloadComponent(0)
            
        }

    }
    //--------------------------------------------------------
    //WorldMap保存
    //--------------------------------------------------------
    @IBAction func saveWorldMap(_ sender: Any) {
        let next = storyboard!.instantiateViewController(withIdentifier: "worldmap") as? WorldMapViewController
        let _ = next?.view // ** hack code **
        self.present(next!,animated: true, completion: nil)
    }
    //--------------------------------------------------------
    //WorldMapスタート
    //--------------------------------------------------------
    @IBAction func startWorldMap(_ sender: Any) {
        self.mapStart = false
    }


}
extension PhotoController: UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var rcount = 0
        if(section == 1){
            let photoCollection = self.realmPhotoList.objects(PhotoNew.self).filter("kind != %@", "0")
            rcount = photoCollection.count
        }else{
            let photoCollection = self.realmPhotoList.objects(PhotoNew.self).filter("kind == %@", "0")
            rcount = photoCollection.count
        }
        return rcount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = (indexPath as NSIndexPath).section
        let cell = tableView.dequeueReusableCell(withIdentifier: "PhotoCell") as! PhotoTableCell
        
        if stage == "1" {
            var photoCollection = self.realmPhotoList.objects(PhotoNew.self)
            if(section == 1){
                photoCollection = self.realmPhotoList.objects(PhotoNew.self).filter("kind != %@", "0")
            }else{
                photoCollection = self.realmPhotoList.objects(PhotoNew.self).filter("kind == %@", "0")
            }
            let photo = photoCollection[indexPath.row]
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(photo.url1)
            let path = fileURL.path
            print("view=" + path)
            let image = UIImage(contentsOfFile: path)
            
            //事前調査時
            cell.Photo1.image = image
            
            if photo.kind == "2" {
                cell.photo_number.text = photo.number + ":" + photo.number_sub
            }else if photo.kind == "0"{
                //現況は写真番号なし
                //cell.photo_number.text = photo.number
                cell.photo_number.text = ""
            }else{
                cell.photo_number.text = photo.number
            }
            var kindStr = ""
            if photo.kind == "0"{
                kindStr = "現況"
            }else if photo.kind == "1" {
                kindStr = "損傷"
                cell.btnCloseup.isHidden = false
            }else{
                kindStr = "損傷（接写）"
            }
            if(photo.status == "0"){
                cell.status.text = "    " + kindStr + " 場所：" + photo.room_name
            }else{
                cell.status.text = "未送信　" + kindStr + " 場所：" + photo.room_name
            }
            if section == 1 && photo.kind == "1"{
                photoList[photo.room_name + ":" + photo.number] = indexPath.row
            }
        }else{
            var photoCollection = self.realmPhotoList.objects(PhotoNew.self)
            if(section == 1){
                photoCollection = self.realmPhotoList.objects(PhotoNew.self).filter("kind != %@", "0")
            }else{
                photoCollection = self.realmPhotoList.objects(PhotoNew.self).filter("kind == %@", "0")
            }
            let photo = photoCollection[indexPath.row]
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(photo.url1)
            let path = fileURL.path
            print("view=" + path)
            let image = UIImage(contentsOfFile: path)
            cell.Photo1.image = image

            let url2 = photo.url2
            print("url2=" + url2)
            if photo.url2 != "" {
                let fileURL2 = documentsURL.appendingPathComponent(photo.url2)
                let path2 = fileURL2.path
                print("view=" + path2)
                let image2 = UIImage(contentsOfFile: path2)
                cell.Photo2.image = image2
            }else{
                let image2 = UIImage(named: "photo")
                cell.Photo2.image = image2
            }
            if photo.kind == "2" {
                cell.photo_number.text = photo.number + ":" + photo.number_sub
            }else if photo.kind == "0"{
                //現況は写真番号なし
                //cell.photo_number.text = photo.number
                cell.photo_number.text = ""
            }else{
                cell.photo_number.text = photo.number
            }
            var kindStr = ""
            if photo.kind == "0"{
                kindStr = "現況"
            }else if photo.kind == "1" {
                kindStr = "損傷"
                cell.btnCloseup.isHidden = false
            }else{
                kindStr = "損傷（接写）"
            }
            if(photo.status == "0"){
                cell.status.text = "    " + kindStr + " 場所：" + photo.room_name
            }else{
                cell.status.text = "未送信　"  + kindStr + " 場所：" + photo.room_name
            }
            if section == 1 && photo.kind == "1"{
                photoList[photo.room_name + ":" + photo.number] = indexPath.row
            }
        }

        return cell
        
    }
}
extension PhotoController: LNZTreeViewDataSource {
    func numberOfSections(in treeView: LNZTreeView) -> Int {
        return 1
    }
    
    func treeView(_ treeView: LNZTreeView, numberOfRowsInSection section: Int, forParentNode parentNode: TreeNodeProtocol?) -> Int {
        guard let parent = parentNode as? Node else {
            return root.count
        }
        
        return parent.children?.count ?? 0
    }
    
    func treeView(_ treeView: LNZTreeView, nodeForRowAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?) -> TreeNodeProtocol {
        guard let parent = parentNode as? Node else {
            return root[indexPath.row]
        }
        
        return parent.children![indexPath.row]
    }
    
    func treeView(_ treeView: LNZTreeView, cellForRowAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?, isExpanded: Bool) -> UITableViewCell {
        
        let node: Node
        if let parent = parentNode as? Node {
            node = parent.children![indexPath.row]
        } else {
            node = root[indexPath.row]
        }
        
        let cell = treeView.dequeueReusableCell(withIdentifier: "cell", for: node, inSection: indexPath.section)
        
        if node.isExpandable {
            if isExpanded {
                cell.imageView?.image = #imageLiteral(resourceName: "index_folder_indicator_open")
            } else {
                cell.imageView?.image = #imageLiteral(resourceName: "index_folder_indicator")
            }
        } else {
            cell.imageView?.image = nil
        }
        
        cell.textLabel?.text = node.photono
        return cell
    }
    func treeView(_ treeView: LNZTreeView, didSelectNodeAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?) {
        let node: Node
        if let parent = parentNode as? Node {
            node = parent.children![indexPath.row]
            print(parent.photono + node.photono)
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: self.photoList[parent.photono + ":" + node.photono]!, section: 1)
                self.photoTableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: false)
            }
        } else {
            node = root[indexPath.row]
            if node.photono == "現況" {
                let indexPath = IndexPath(row: 0, section: 1)
                self.photoTableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: false)
            }
        }
        
        
    }
}

extension PhotoController: LNZTreeViewDelegate {
    func treeView(_ treeView: LNZTreeView, heightForNodeAt indexPath: IndexPath, forParentNode parentNode: TreeNodeProtocol?) -> CGFloat {
        return 30
    }
}
