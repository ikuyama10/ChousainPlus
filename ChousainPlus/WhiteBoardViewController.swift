//
//  WhiteBoardViewController.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/01/28.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import RealmSwift

class WhiteBoardViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource,  UITextFieldDelegate {
    @IBOutlet weak var txtInput: UITextField!
    var wb_id :String = "0"
    var research_id :String = ""
    var building_id :String = ""
    var owner_id :String = ""
    var stage :String = "0"
    var selctedItem = 0
    var room_name :String = ""
    var photo_number :String = ""
    var photo_mode:Int = 2
    var L_str :String = ""
    var W_str :String = ""

    let realmDictionary = try! Realm()
    var compos = [""]
    
    @IBOutlet var labelArray: [UILabel] = []
    
    @IBOutlet var buttonArray: [UIButton] = []
    
    @IBOutlet weak var selctItem: UIPickerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtInput.delegate = self
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        let defaults = UserDefaults.standard
        research_id = defaults.string(forKey: "research_id")!
        building_id = defaults.string(forKey: "building_id")!
        stage = defaults.string(forKey: "stage")!
        
        selctItem.delegate = self
        selctItem.dataSource = self
        
        makeWhiteBoard()
        
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        buttonArray[selctedItem].setTitle(txtInput.text, for: .normal)
        return true
    }
    @IBAction func finishView(_ sender: Any) {
        if photo_mode == 2{
            let controller = self.presentingViewController as? CameraViewController
            self.dismiss(animated: true, completion: {
                controller?.viewWhiteBoard(room: self.room_name)
            })
        }else{
            let controller = self.presentingViewController as? CameraCloseupViewController
            self.dismiss(animated: true, completion: {
                controller?.viewWhiteBoard(room: self.room_name)
            })
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return compos.count
    }
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 150
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return compos[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let item = compos[row]
        buttonArray[self.selctedItem].setTitle(item, for: .normal)
    }
    
    @IBAction func key0(_ sender: Any) {
        var button = sender as! UIButton
        var str:String = (button.titleLabel?.text)!
        if (str == "スペース") {
            str = " "
        }else if (str == "クリア") {
            txtInput.text = ""
            str = ""
        }else if (str == "BS") {
            let nstr :String = txtInput.text ?? ""
            txtInput.text = String(nstr.prefix(nstr.count - 1))
            str = ""
            
        }
        let str2:String = txtInput.text!
        
        //str2?.append(contentsOf: str ?? <#default value#>)
        let stext = str2 + str
        txtInput.text = stext
        buttonArray[selctedItem].setTitle(stext, for: .normal)
        
    }
    
    func makeWhiteBoard(){
        let realmWhiteBoard = try! Realm()
        let whiteBoardCollection = realmWhiteBoard.objects(WhiteBoardDictionary.self).filter("wbid == %@", self.wb_id)
        var cnt = 0;
        var room_name_index = 0
        
        for wb in whiteBoardCollection {
            //print(wb.item_no + " " + wb.item_name)
            labelArray[cnt].text = wb.item_name
            labelArray[cnt].frame  = CGRect(x:Int(wb.dsp_x)! * 30 + 6, y:Int(wb.dsp_y)! * 30 + 100, width: Int(wb.width)! * 30, height: 50);
            labelArray[cnt].numberOfLines = 2
            labelArray[cnt].isHidden = false
            
            let no = Int(wb.item_no)
            if(no! < 10){
                buttonArray[cnt].frame  = CGRect(x:(Int(wb.dsp_x)! + 3) * 30, y:Int(wb.dsp_y)! * 30 + 110, width: (Int(wb.width)! - 3) * 30, height: Int(wb.height)! * 30 );
                buttonArray[cnt].setTitle("", for: .normal)
                buttonArray[cnt].isHidden = false
            }

            //データ取得
            getItemValue(item_no: wb.item_no, count :cnt, item : wb.item_name)

            //右罫線
            var frame:CGRect = CGRect(x:Int(wb.dsp_x)! * 30 + Int(wb.width)! * 30, y:Int(wb.dsp_y)! * 30 + 110, width: 3, height: Int(wb.height)! * 30)
            var line:WhiteboardRuleLine = WhiteboardRuleLine(frame: frame)
            self.view.addSubview(line)

            //右罫線
            if(wb.rule != "2"  && wb.rule != "3"){
                frame = CGRect(x:Int(wb.dsp_x)! * 30 + 3 * 30, y:Int(wb.dsp_y)! * 30 + 110, width: 3, height: Int(wb.height)! * 30)
                line = WhiteboardRuleLine(frame: frame)
                self.view.addSubview(line)
            }
            //上罫線
            if(wb.rule != "1" && wb.rule != "3"){
                frame = CGRect(x:Int(wb.dsp_x)! * 30, y:Int(wb.dsp_y)! * 30 + 110, width: Int(wb.width)! * 30, height: 3)
                line = WhiteboardRuleLine(frame: frame)
                self.view.addSubview(line)
            }
            if(wb.item_name == "場所"){
                room_name_index = Int(wb.item_no)! - 1
            }
            cnt += 1
        }
        var frame:CGRect = CGRect(x:30, y: 140, width: 3, height: 16 * 30 - 3)
        var line:WhiteboardRuleLine = WhiteboardRuleLine(frame: frame)
        self.view.addSubview(line)
        /*
        frame = CGRect(x:30 * 17, y: 140, width: 3, height: 17 * 30)
        line = WhiteboardRuleLine(frame: frame)
        self.view.addSubview(line)
        */
        frame = CGRect(x:30, y: 137 + 16 * 30, width: 30 * 16, height: 3)
        line = WhiteboardRuleLine(frame: frame)
        self.view.addSubview(line)
        
        //初期値セット
        let whiteBoard = WhiteBoardData.shared
        for i in 0..<10 {
            buttonArray[i].setTitle(whiteBoard.items[i], for: .normal)
            if i == 5 {
                buttonArray[i].setTitle(self.L_str, for: .normal)
            }
            if i == 4 {
                buttonArray[i].setTitle(self.W_str, for: .normal)
            }
        }
        //写真番号、測定ヶ所（部屋）は決めている---------------------------------------
        if room_name_index < 10 {
            buttonArray[room_name_index].setTitle(room_name, for: .normal)
        }else{
            labelArray[room_name_index].text = room_name
        }
    }
    
    func getItemValue(item_no :String, count :Int, item :String){
        let no = Int(item_no)
        
        if(no! <= 10){
            let whiteBoard = WhiteBoardData.shared
            labelArray[count].text = item
        }
        if(no == 11 || no == 12){
            let realmResearch = try! Realm()
            let researchCollection = realmResearch.objects(ResearchStage.self).filter("id == %@", self.research_id)
            
            if(no == 11){
                labelArray[count].text = researchCollection[0].name
            }else{
                //labelArray[count].text = researchCollection[0].name_second
                //Research1から
            }
        }
        if(no == 15){
            let realmBuilding = try! Realm()
            let buildingCollection = realmBuilding.objects(Building.self).filter("id == %@", self.building_id)
            labelArray[count].text = "建物番号 " + buildingCollection[0].property_no
        }
        
        if(no == 13 || no == 16){
            let realmBuilding = try! Realm()
            let buildingCollection = realmBuilding.objects(Building.self).filter("id == %@", self.building_id)
            let building = buildingCollection[0]
            owner_id = building.owner_id

            let realmOwner = try! Realm()
            let ownerCollection = realmOwner.objects(Owner.self).filter("id == %@", owner_id)
            if(no == 13){
                labelArray[count].text = "調査番号　" + ownerCollection[0].owner_number
            }else{
                labelArray[count].text = "所有者　　" + ownerCollection[0].owner_name
            }
        }
        if(no == 14){
            let now = Date() // 現在日時の取得
            let dateFormatter = DateFormatter()
            dateFormatter.locale = NSLocale(localeIdentifier: "en_JP") as Locale // ロケールの設定
            dateFormatter.dateFormat = "yyyy年M月d日" // 日付フォーマットの設定
            let date = dateFormatter.string(from: now as Date)
            labelArray[count].text = "調査日時　" + date
        }
        if no == 17 {
            labelArray[count].text = "写真番号　" + self.photo_number
        }
        
    }
    @IBAction func captureWhiteboard(_ sender: Any) {
        selctItem.isHidden = true
        //白板データ保存
        let whiteBoard = WhiteBoardData.shared
        for i in 0..<10 {
            whiteBoard.items[i] = buttonArray[i].currentTitle!
            if i == 0 {
                self.room_name = whiteBoard.items[i]
            }
        }
        //白板画像保存
        buttonArray[selctedItem].backgroundColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 1)
        // キャプチャ画像を取得.
        //コンテキスト開始
        let area = view.bounds
        UIGraphicsBeginImageContextWithOptions(area.size, false, 0.0)
        //viewを書き出す
        self.view.drawHierarchy(in: area, afterScreenUpdates: true)
        // imageにコンテキストの内容を書き出す
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        let area2 = CGRect(x:20,y:120, width: view.bounds.width / 2, height : view.bounds.height - 200)
        let image2 :UIImage = image.cropping(to: area2)!
        //コンテキストを閉じる
        UIGraphicsEndImageContext()
        
        //画像の保存
        let filename = "whiteboard.jpg"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(filename)
        print("save="+fileURL.path)
        do {
            let jpgImage = image2.jpegData(compressionQuality: 1.0)
            try jpgImage!.write(to: fileURL)
        } catch {
            //エラー処理
            print("Error")
        }
        
        //----------------------------------------------------------------------------現況、損傷社員の場合
        if photo_mode == 2{
            let controller = self.presentingViewController as? CameraViewController
            self.dismiss(animated: true, completion: {
                controller?.viewWhiteBoard(room: self.room_name)
            })
        }else{
            let controller = self.presentingViewController as? CameraCloseupViewController
            self.dismiss(animated: true, completion: {
                controller?.viewWhiteBoard(room: self.room_name)
            })
        }
    }
    @IBAction func itemSelect(_ sender: Any) {
        let button = sender as! UIButton
        let tag = button.tag
        //print (tag)
        buttonArray[selctedItem].backgroundColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: 1)
        buttonArray[selctedItem].isHidden = false
        button.backgroundColor = UIColor.init(red: 0.2, green: 0.8, blue: 1, alpha: 0.5)
        selctedItem = tag
        txtInput.text = buttonArray[selctedItem].currentTitle
        
        //辞書検索
        let realmWhiteBoard = try! Realm()
        let whiteBoardCollection = realmWhiteBoard.objects(WhiteBoardDictionary.self).filter("wbid == %@ && item_no == %@", self.wb_id, String(selctedItem + 1))

        let realmDictionary = try! Realm()
        let DictionaryCollection = realmDictionary.objects(Dictionary.self).filter("wbid == %@ && item_id == %@", self.wb_id, String(selctedItem + 1))
        compos.removeAll()
        if(DictionaryCollection.count > 0){
            button.isHidden = true
            for dictionary in DictionaryCollection {
                compos.append(dictionary.item)
            }
            selctItem.reloadComponent(0)
            selctItem.frame  = CGRect(x:(Int(whiteBoardCollection[0].dsp_x)! + 3) * 30 + 6, y:Int(whiteBoardCollection[0].dsp_y)! * 30 + 100, width: (Int(whiteBoardCollection[0].width)! - 3) * 30, height: 80);
            selctItem.isHidden = false
        }else{
            selctItem.isHidden = true
        }
    }
}
extension UIImage {
    func cropping(to: CGRect) -> UIImage? {
        var opaque = false
        if let cgImage = cgImage {
            switch cgImage.alphaInfo {
            case .noneSkipLast, .noneSkipFirst:
                opaque = true
            default:
                break
            }
        }
        
        UIGraphicsBeginImageContextWithOptions(to.size, opaque, scale)
        draw(at: CGPoint(x: -to.origin.x, y: -to.origin.y))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
}
