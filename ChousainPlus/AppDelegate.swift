//
//  AppDelegate.swift
//  ChousainPlus
//
//  Created by yamaguchi on 2019/01/24.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

class WhiteBoardData {
    private init() {}
    static let shared = WhiteBoardData()
    
    var items = ["","","","","","","","","",""]
        
    func clear(){
        for i in 0..<10 {
            items[i] = ""
        }
    }
}
//他クラスからの参照
//var whiteBoard = WhiteBoard.shared
//print(whiteBoard.items[0])

class PhotoNumber {
    private init() {}
    static let shared = PhotoNumber()
    
    var photo_num = [1,1,1,1,1]   //写真番号の初期値をユーザーごとに変えられるようにする
    var photo_gen_num = [1,1,1,1,1]   //写真番号の初期値をユーザーごとに変えられるようにする
    var room_name = ["","","","",""]
    var division = ""
    var pre_stage = 1
    var width:Float = 0.0

    func initial(num:Int){
        for i in 0..<5 {
            photo_num[i] = num
            photo_gen_num[i] = num
        }
    }
}
