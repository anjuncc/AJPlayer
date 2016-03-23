//
//  ViewController.swift
//  avplayer
//
//  Created by anjun on 16/3/18.
//  Copyright © 2016年 cptrue. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
class ViewController: UIViewController {
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let s = "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"
//        let s=""http://192.168.130.109:90/jp3.mp4"
        
        if  let url =  NSURL(string: s){
 
       let avPlayer = AVPlayer(URL: url)
      let  avPlayerLayer = AVPlayerLayer(player: avPlayer)
        avPlayerLayer.frame = self.view.frame
        self.view.layer.addSublayer(avPlayerLayer)
        avPlayer.seekToTime(kCMTimeZero)
        avPlayer.play()
    }
        
        
        
//        if  let url =  NSURL(string: "http://192.168.130.109:90/jp3.mp4")
//             {
//           let player = AVPlayer(URL: url)
//            let playerViewController = AVPlayerViewController()
//            playerViewController.player = player
//            self.presentViewController(playerViewController, animated: true) {
//                if let validPlayer = playerViewController.player {
//                    validPlayer.play()
//                }
//            }
//        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if((self.navigationController) != nil){
            self.navigationController!.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
            self.navigationController!.navigationBar.shadowImage = UIImage()
        }
        var videoUrl: NSURL = NSURL(string: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")!
        
//        let playView = PlayVideoView();
//        
//        self.view.addSubview(playView);
//      

//        var  playerItem = AVPlayerItem(URL: videoUrl);
//        playerItem.addObserver(self, forKeyPath: "status", options: .New, context: nil)
//        // 监听status属性
//        playerItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: .New, context: nil)
//        // 监听loadedTimeRanges属性
//        playView.player = AVPlayer(playerItem: playerItem);
//       
  


    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func play1(){
        var videoUrl: NSURL = NSURL(string: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")!
        let player = AVPlayer(URL: videoUrl)
        let playerController = AVPlayerViewController()
        
        playerController.player = player
        self.addChildViewController(playerController)
        self.view.addSubview(playerController.view)
        playerController.view.frame = self.view.frame
        
        player.play()
    }

}

