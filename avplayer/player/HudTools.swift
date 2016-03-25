//
//  HudTools.swift
//  avplayer
//
//  Created by anjun on 16/3/23.
//  Copyright © 2016年 cptrue. All rights reserved.
//
import UIKit
import Foundation
class HudTools{
    static let shared = HudTools()
    init(){
        SVProgressHUD.setDefaultStyle(.Custom)
        SVProgressHUD.setBackgroundColor(UIColor(red: 0, green: 0, blue: 0, alpha: 0.5))
        SVProgressHUD.setForegroundColor(UIColor.whiteColor())
//        SVProgressHUD.setMinimumDismissTimeInterval(0.05)
    }
    
    func showBackward(v:UIView,msg:String){
        SVProgressHUD.showImage(UIImage(named: "ScanBackwardButton"), status: msg)
    }
    func showForward(v:UIView,msg:String){
        SVProgressHUD.showImage(UIImage(named: "ScanForwardButton"), status: msg)
    }
    func showVoice(v:UIView,msg:String){
        SVProgressHUD.showImage(UIImage(named: "volumeBtn"), status: msg)
    }
    func showBrightless(v:UIView,msg:String){
        SVProgressHUD.showImage(UIImage(named: "brightnessBtn"), status: msg)
    }
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
}