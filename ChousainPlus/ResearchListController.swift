//
//  ResearchListController.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/01/25.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import RealmSwift

class ResearchListController: UIViewController ,UITableViewDelegate, UITableViewDataSource{
    var count = 0
    let realm = try! Realm()
    let realmBuilding = try! Realm()
    var research_cnt = 0
    var building_cnt = 0
    var research_id :String = "1"
    var stage :String = "0"

    @IBOutlet weak var buildingTableView: UITableView!
    @IBOutlet weak var reaportTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //self.title = "調査一覧"
        print(Realm.Configuration.defaultConfiguration.fileURL!)

        let reserchCollection = realm.objects(ResearchStage.self)
        research_cnt = reserchCollection.count

        //調査の初期値
        let reserch = reserchCollection[0]
        self.research_id = reserch.id
        self.stage = reserch.stage
        print("research_id=" + research_id)

        let buildingCollection = realmBuilding.objects(Building.self).filter("research_id == %@", self.research_id)
        building_cnt = buildingCollection.count

    }
    override func viewWillAppear(_ animated: Bool) {
        //一行目を選択状態に
        let indexpath: IndexPath = IndexPath(row: 0, section: 0)
        reaportTableView.selectRow(at: indexpath, animated: true, scrollPosition: .bottom)
        
    }
    @IBAction func AddItem(_ sender: Any) {
        performSegue(withIdentifier: "Upload", sender: nil)
    }
    @IBAction func returnTo(segue: UIStoryboardSegue){
        //画面のリロード
        //loadView()
        //viewDidLoad()
    }
    //RserchTableView関連
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        var rcnt = 0;
        if(tableView.tag == 0){
            rcnt = self.research_cnt
        }else{
            rcnt = self.building_cnt
        }
        return  rcnt
    }
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell{
        let tag = tableView.tag
        if(tag == 0){
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReserchCell") as! ReserchTableCell
            let reserchCollection = realm.objects(ResearchStage.self)
            let reserch = reserchCollection[indexPath.row]
            cell.ReserchName.text = reserch.name
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "BuildingCell") as! BuildingTableCell
            
            let buildingCollection = realmBuilding.objects(Building.self).filter("research_id == %@", self.research_id)
            let building = buildingCollection[indexPath.row]
            cell.BuildingName.text = building.property_no
            return cell
        }
        
    }
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(tableView.tag == 0){
            let reserchCollection = realm.objects(ResearchStage.self)
            let reserch = reserchCollection[indexPath[1]]
            self.research_id = reserch.id
            self.stage = reserch.stage
            print("research_id=" + research_id)
            
            let buildingCollection = realmBuilding.objects(Building.self).filter("research_id == %@", self.research_id)
            building_cnt = buildingCollection.count
            buildingTableView.reloadData()

        }else{
            print("物件 "+String(indexPath[1]))
            let buildingCollection = realmBuilding.objects(Building.self).filter("research_id == %@", self.research_id)
            let building = buildingCollection[indexPath[1]]
            let building_id = building.id
            let defaults = UserDefaults.standard
            defaults.set(research_id, forKey:"research_id")
            defaults.set(building_id, forKey:"building_id")
            defaults.set(stage, forKey:"stage")

            //写真リスト画面表示
            performSegue(withIdentifier: "Photo", sender: nil)

        }
    }
    
    @IBAction func logout(_ sender: Any) {
        //未送信の写真がある場合、送信を行う（確認）---------------------------------------------------------------
        
        let defaults = UserDefaults.standard
        defaults.set("", forKey:"user")
        defaults.set("", forKey:"pass")
        
        let next = storyboard!.instantiateViewController(withIdentifier: "login") as? LoginController
        let _ = next?.view // ** hack code **
        self.present(next!,animated: true, completion: nil)
    }
}
