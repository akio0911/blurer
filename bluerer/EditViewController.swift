//
//  EditViewController.swift
//  bluerer
//
//  Created by Masaki Horimoto on 2016/03/22.
//  Copyright © 2016年 Masaki Horimoto. All rights reserved.
//

import UIKit

class EditViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIScrollViewDelegate  {

    @IBOutlet weak var displayView: UIView!
    @IBOutlet weak var pictureView: UIImageView!
    @IBOutlet weak var blurView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var image : UIImage?        //ライブラリから取得した写真が入る
    var is1st: Bool = false     //viewDidLoadを通った直後か否かを判断
    
    var lastPoint: CGPoint!
    
    var red: CGFloat = 1.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var alpha: CGFloat = 0.0
    var val: CGFloat = 5.0
    var blendMode: CGBlendMode = .Clear
    var color: UIColor?
    var bezierPath: UIBezierPath?
    var firstMovedFlg: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.delegate = self
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0    // 最小拡大率
        scrollView.maximumZoomScale = 4.0    // 最大拡大率
        scrollView.zoomScale = 1.0           // 表示時の拡大率
        
        //imageに値が入っているか確認. 入っていなければreturnする.
        guard (image != nil) else {
            print("Cannot access PhotoLibrary.")
            return
        }


        pictureView.contentMode = .ScaleAspectFit   //contentModeの設定
        pictureView.image = image                   //pictureViewにimageを適応
        
        let ev = createBlurView(pictureView)        //ぼかしViewの作成
        blurView.contentMode = .ScaleAspectFit      //contentModeの設定
        blurView.image = image
        blurView.addSubview(ev)                     //ぼかしViewをblurViewにAdd
        
        //navigationControllerにアクセス出来るか確認. 出来なければFatalError.
        guard let navigationController = self.navigationController else {
            fatalError("navigationController is invalid.")
        }
        
        //bar周りの表示設定. ここでは非表示に.
        navigationController.navigationBarHidden = true
        navigationController.toolbarHidden = true
        
        //ここでtrueにする (viewDidAppearでfalseに戻す)
        is1st = true
        
        let myPan = UIPanGestureRecognizer(target: self, action: "panGesture:")
        myPan.maximumNumberOfTouches = 1
        self.scrollView.addGestureRecognizer(myPan)
        
        //scrollView.scrollEnabled = false
        
    }
    
    override func viewDidLayoutSubviews() {
        print("\(NSStringFromClass(self.classForCoder)).\(__FUNCTION__) is called!")
        //navigationBarを表示した時に写真が少し下にずれる問題の対策.
        self.scrollView.contentInset = UIEdgeInsetsZero
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        if !is1st { return }
        
        //navigationControllerにアクセス出来るか確認. 出来なければFatalError.
        guard let navigationController = self.navigationController else {
            fatalError("navigationController is invalid.")
        }
        
        //アニメーションしてbarを表示する
        let isDisplayBar = navigationController.navigationBarHidden
        navigationController.setNavigationBarHidden(!isDisplayBar, animated: true)
        navigationController.setToolbarHidden(!isDisplayBar, animated: true)
        
        //ここでfalseにする (役割おしまい)
        is1st = false
    
    }
    
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        print("\(NSStringFromClass(self.classForCoder)).\(__FUNCTION__) is called!")
        return self.displayView
    }
    

    /**
     引数のimageViewを基にぼかしViewを作成する
     
     - parameter imageView : ぼかし画像の元画像
     */
    private func createBlurView(imageView: UIImageView) -> SABlurImageView {
 
        let ev = SABlurImageView(image: imageView.image)
        
        ev.frame = imageView.frame
        let ratio = imageView.image!.size.height / imageView.image!.size.width
        ev.frame = CGRectMake(0, 0, imageView.frame.width, imageView.frame.width * ratio)
        ev.center = imageView.center
        ev.layer.masksToBounds = true
        ev.addBlurEffect(100, times: 3)
        
        return ev
 
    }

    
    internal func panGesture(sender: AnyObject) {
        
        print("\(NSStringFromClass(self.classForCoder)).\(__FUNCTION__) is called!")
        
        guard let pan = sender as? UIPanGestureRecognizer else { return }
        
        let touchPoint = pan.locationInView(pictureView)
        
        switch pan.state {
        case .Began:
            print("Start dragging")
            lastPoint = touchPoint
            
            bezierPath = UIBezierPath()
            bezierPath!.lineCapStyle = .Round
            bezierPath!.lineWidth = 10.0
            bezierPath!.moveToPoint(touchPoint)
            firstMovedFlg = false
            
        case .Changed:
            
            let newPoint = touchPoint

            guard let bezierPath_ = bezierPath else {
                
                print("guard")
                return
            }
            
            if !firstMovedFlg {
                firstMovedFlg = true
                lastPoint = newPoint;
                return
            }
            
            
            
            let middlePoint = CGPointMake((lastPoint.x + newPoint.x) / 2, (lastPoint.y + newPoint.y) / 2)
            
            bezierPath_.addQuadCurveToPoint(middlePoint, controlPoint: lastPoint)
            
            UIGraphicsBeginImageContextWithOptions(self.pictureView.bounds.size, false, 0.0)
            let ratio = self.pictureView.image!.size.height / self.pictureView.image!.size.width
            self.pictureView.image?.drawInRect(CGRectMake(0, (self.pictureView.bounds.size.height - self.pictureView.bounds.size.width * ratio) / 2, self.pictureView.bounds.size.width, self.pictureView.bounds.size.width * ratio))
            
            color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
            bezierPath_.strokeWithBlendMode(blendMode, alpha: alpha) //透明色
            
            color!.setStroke()
            
            bezierPath_.stroke()
            
            self.pictureView.image = UIGraphicsGetImageFromCurrentImageContext()
            
            UIGraphicsEndImageContext()
            
            lastPoint = newPoint
            
            
        case .Ended:
            print("Finish dragging")
        default:
            ()
        }
        
    }
}
