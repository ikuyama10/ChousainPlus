//
//  PhotoViewController.swift
//  ChousainPlus
//
//  Created by ZeroSpace on 2019/02/22.
//  Copyright © 2019 山口　郁準. All rights reserved.
//

import UIKit
import RealmSwift

class PhotoViewController: UIViewController , UIScrollViewDelegate {
    var filename1 :String = ""
    var filename2 :String = ""
    var dsp :Int = 1
    var wb_id :String = "1"
    var division:String = "1"
    var photo_num :Int = 0
    var photo_mode :Int = 1
    var room_name :String = ""
    var stage :String = "1"
    
    var currentScale:CGFloat = 1.0
    var startPoint = CGPoint()
    var endPoint = CGPoint()

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var btnCloseup: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        var fileURL = documentsURL.appendingPathComponent(filename1)
        if dsp == 2{
            fileURL = documentsURL.appendingPathComponent(filename2)
        }
        let path = fileURL.path
        image.image = UIImage(contentsOfFile: path)
        image.contentMode = .scaleAspectFit
        
        //損傷写真の場合、接写ボタンを表示
        if(photo_mode != 2){
            //self.btnCloseup.isHidden = true
        }
        self.scrollView.delegate = self
        if (self.scrollView.zoomScale < self.scrollView.maximumZoomScale) {
            let newScale = self.scrollView.zoomScale * 3
            let zoomRect = self.zoomRectForScale(scale: newScale, center: view.center)
            self.scrollView.zoom(to: zoomRect, animated: true)
        } else {
            self.scrollView.setZoomScale(1.0, animated: true)
        }
    }
    @IBAction func closeUpPhoto(_ sender: Any) {
        let next = storyboard!.instantiateViewController(withIdentifier: "closeup") as? CameraCloseupViewController
        let _ = next?.view // ** hack code **
        
        //next?.filename1 = photo.url
        next?.wb_id = self.wb_id
        next?.division = self.division
        next?.photo_num = self.photo_num
        next?.room_name = self.room_name

        self.present(next!,animated: true, completion: nil)
    }
    @IBAction func deletePhoto(_ sender: Any) {
        //写真データの削除
        
        //------------------------------------------------------------------------------削除時にユーザーに確認する
        
        //let realmPhoto = try! Realm()
        //let results = realmPhoto.objects(Photo.self).filter("url == %@",self.filename1)
        let realmPhotoList = try! Realm()
        let realmPhoto = try! Realm()
        var status = "0"
        if stage == "1" {
            let results = realmPhotoList.objects(PhotoNew.self).filter("url1 == %@",self.filename1)
                if results.count > 0 {
                status = results[0].status
                if(status == "1"){
                    try! realmPhotoList.write {
                        realmPhotoList.delete(results)
                    }
                }
            }
            let results2 = realmPhoto.objects(Photo.self).filter("url == %@",self.filename1)
            if results2.count > 0 {
                status = results2[0].status
                if(status == "1"){
                    try! realmPhoto.write {
                        realmPhoto.delete(results2)
                    }
                }
            }
        }else{
            let results = realmPhotoList.objects(PhotoNew.self).filter("url2 == %@",self.filename2)
            if results.count > 0 {
                try! realmPhotoList.write {
                    results[0].url2 = ""
                }
            }
            let results2 = realmPhoto.objects(Photo.self).filter("url == %@",self.filename2)
            if results2.count > 0 {
                status = results2[0].status
                if(status == "1"){
                    try! realmPhoto.write {
                        realmPhoto.delete(results2)
                    }
                }
            }
        }
        //アップロードしていない写真のみ削除可能
        if(status == "1"){
            //写真の除去
            let photoManager = PhotoManager()
            photoManager.deletePhoto(filename: filename1)
            
            let controller = self.presentingViewController as? PhotoController
            self.dismiss(animated: true, completion: {
                controller?.updateTableView()
            })
        }else{
            let alert = UIAlertController(title: "この写真は既に送信済みのため削除できません", message: "PCで削除してください", preferredStyle: .alert)
            alert.addAction(
                UIAlertAction(title:"OK", style: .default, handler: {(action) ->Void in self.alertFinish()})
            )
            self.present(alert, animated: true, completion:{}
            )
        }
    }
    func alertFinish(){
        
    }
    @IBAction func finishVIew(_ sender: Any) {
        //self.dismiss(animated: true, completion: nil)
        let next = storyboard!.instantiateViewController(withIdentifier: "photolist") as? PhotoController
        let _ = next?.view // ** hack code **
        
        self.present(next!,animated: true, completion: nil)
        
    }
    @IBAction func pinchAction(_ sender: UIPinchGestureRecognizer) {
        switch sender.state {
        case .began, .changed:
            // senderのscaleは、指を動かしていない状態が1.0となる
            // 現在の拡大率に、(scaleから1を引いたもの) / 10(補正率)を加算する
            currentScale = currentScale + (sender.scale - 1) / 10
            // 拡大率が基準から外れる場合は、補正する
            if currentScale < 1.0 {
                currentScale = 1.0
            } else if currentScale > 4.0 {
                currentScale = 4.0
            }
            
            // 計算後の拡大率で、imageViewを拡大縮小する
            self.image.transform = CGAffineTransform(scaleX: currentScale, y: currentScale)
        default:
            // ピンチ中と同様だが、拡大率の範囲が異なる
            if currentScale < 1.0 {
                currentScale = 1.0
            } else if currentScale > 3.0 {
                currentScale = 3.0
            }
            
            // 拡大率が基準から外れている場合、指を離したときにアニメーションで拡大率を補正する
            // 例えば指を離す前に拡大率が0.3だった場合、0.2秒かけて拡大率が0.5に変化する
            UIView.animate(withDuration: 0.2, animations: {
                self.image.transform = CGAffineTransform(scaleX: self.currentScale, y: self.currentScale)
            }, completion: nil)
            
        }
        print (sender.description)
        if (self.scrollView.zoomScale < self.scrollView.maximumZoomScale) {
            let newScale = self.scrollView.zoomScale * 3
            let zoomRect = self.zoomRectForScale(scale: newScale, center: view.center)
            self.scrollView.zoom(to: zoomRect, animated: true)
        } else {
            self.scrollView.setZoomScale(1.0, animated: true)
        }
    }
    @IBAction func tapAction(_ sender: UITapGestureRecognizer) {
        //print(self.myScrollView.zoomScale)
        image.center.x = image.bounds.width / 2
        image.center.y = image.bounds.height / 2
    }
    func zoomRectForScale(scale:CGFloat, center: CGPoint) -> CGRect{
        
        let size = CGSize(
            width: self.scrollView.frame.size.width / scale,
            height: self.scrollView.frame.size.height / scale
        )
        return CGRect(
            origin: CGPoint(
                x: center.x - size.width / 2.0,
                y: center.y - size.height / 2.0
            ),
            size: size
        )
    }
    
    @IBAction func panAction(_ sender: UIPanGestureRecognizer) {
        let tapLoc = sender.location(in: self.view)
        //print("pan")
        let xscale = image.bounds.width * self.currentScale
        let scX = image.center.x
        let X = image.bounds.width
        let x0 = image.center.x - xscale / 2
        let x1 = image.center.x + xscale / 2
        print("xscale=" + xscale.description + ",X=" + X.description + ",x0=" + x0.description + ",x1=" + x1.description + ",scX=" + scX.description)
        switch sender.state.rawValue{
        case 1:
            print("start ")
            startPoint = tapLoc
            break
        case 2:
            //print( "x0=" + x0.description)
            endPoint = tapLoc
            //imageを移動する
            image.center.x = image.center.x - (startPoint.x - endPoint.x)
            image.center.y = image.center.y - (startPoint.y - endPoint.y)
            
            //let x0 = image.center.x - image.bounds.x / 2.0
            startPoint = tapLoc
            break
        case 3:
            print("end")
            endPoint = tapLoc
            endPoint = tapLoc
            //imageを移動する
            image.center.x = image.center.x - (startPoint.x - endPoint.x)
            image.center.y = image.center.y - (startPoint.y - endPoint.y)
            break
        default:
            break
            
        }
        
    }
    
}
