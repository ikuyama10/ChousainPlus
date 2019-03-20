//
//  ViewController.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/01/24.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit

class LoginController: UIViewController {
    var login = false;
    var dic  = [String : Any]()
    let defaults = UserDefaults.standard
    var timer :Timer!
    @IBOutlet weak var user: UITextField!
    @IBOutlet weak var pass: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(LoginController.timerUpdate), userInfo: nil, repeats: true)
        let user = self.defaults.string(forKey: "user")
        
        if (user != nil && user != "") {
            let pass = self.defaults.string(forKey: "pass")
            self.user.text = user
            self.pass.text = pass
            //self.login(user: user, pass: pass)
            
            self.login = true //-----------------------------------------------一回ログインしたらサーバーに問い合わせない場合
        }
        
    }
    @objc func timerUpdate() {
        if(login == true){
            self.timer.invalidate()
            self.performSegue(withIdentifier: "Sync", sender: self)
        }
    }
    @IBAction func Login(_ sender: Any) {
        //let httpManager = HttpManager()
        //httpManager.delegate = self
        /// NotificationCenterを登録
        //NotificationCenter.default.addObserver(self, selector: #selector(comeback(notification:)), name: .notifyName, object: nil)
        //非同期の場合通信OFFでもログインする
        //保存のpassが有る場合　保存passと比較

        self.login(user: self.user.text!, pass: self.pass.text!)
    }
    /*
    @objc internal func comeback(notification: NSNotification) {
        
        // 通知を解除する
        //NotificationCenter.default.removeObserver(self)
        //画面遷移
        //let reserchList = self.storyboard?.instantiateViewController(withIdentifier: "ReserchList")
        //present(reserchList!,animated: false,completion: nil)
        login = true;
    }
    */
    func login(user : String, pass : String){
        httpPost(call: "login.php", parameter :"user="+user+"&pass="+pass)
    }
    func httpPost(call : String, parameter: String){
        let httpManager = HttpManager()
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
                self.dic = try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String: Any]
                
                print("LOGIN")
                //print("name: \(self.dic["name"] as! String)")
                //print("id: \(self.dic["id"] as! String)")
                let name = self.dic["name"] as! String
                let userid = self.dic["id"] as! String
                let key = self.dic["keycode"] as! String
                //データ保存
                do{
                    self.defaults.set(name, forKey:"name")
                    self.defaults.set(self.user.text!, forKey:"user")
                    self.defaults.set(self.pass.text!, forKey:"pass")
                    self.defaults.set(userid, forKey:"userid")
                    self.defaults.set(key, forKey:"keycode")

                    self.login = true
                    session.finishTasksAndInvalidate()
                } catch let error as NSError {
                    session.finishTasksAndInvalidate()
                }
                
            }else{
                print("login")
            }
            }.resume()
        
    }
    /*
    struct ParseError: Error {}
    func parse(json: String) throws {
        guard let data = json.data(using: .utf8) else {
            throw ParseError()
        }
        let json = try JSONSerialization.jsonObject(with: data)
        guard let rows = json as? [[String:Any]] else {
            throw ParseError()
        }
        for row in rows {
            let name = row["name"] ?? ""
            let age = row["age"] ?? 0
            print("\(name) is \(age)")
        }
    }
    */
}


