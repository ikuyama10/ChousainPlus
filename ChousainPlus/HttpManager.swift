//
//  HttpManager.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/01/30.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
protocol TaskDelegate {
    func complete(result: String)
    func failed(error: NSError)
}
final class HttpManager: NSObject {
    var dic  = [String : Any]()
    //let urlBase = "https://iyproject.space/api/"
    //let urlBase = "http://52.194.184.38/chousainplus/api/"
    //let urlPhotoBase = "http://52.194.184.38/efs_data/"
    
    let urlBase = "https://api.chousainplus.com/chousainplus/api/"
    //let urlBase = "https://api.chousainplus.com/chousainplus/api_test/"
    let urlPhotoBase = "https://api.chousainplus.com/efs_data/"

    func getUrl() -> String{
        return urlBase
    }
    func getPhotoUrl() -> String{
        return urlPhotoBase
    }
    struct ParseError: Error {}
    func parse(json: String) throws -> [[String:Any]]{
        guard let data = json.data(using: .utf8) else {
            throw ParseError()
        }
        let json = try JSONSerialization.jsonObject(with: data)
        guard let rows = json as? [[String:Any]] else {
            throw ParseError()
        }
        return rows
    }
    /*
    func login(user : String, pass : String){
        httpPost(call: "login.php", parameter :"user="+user+"&pass="+pass)
    }
    func httpPost(call : String, parameter: String){
        let url = URL(string: urlBase + call)
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
                
                //print("name: \(self.dic["name"] as! String)")
                //print("id: \(self.dic["id"] as! String)")
                NotificationCenter.default.post(name: .notifyName, object: nil)
            }
            }.resume()
        
    }
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
/*
extension Notification.Name {
    static let notifyName = Notification.Name("notifyName")
}
 */
