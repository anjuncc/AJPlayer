/*
	Copyright (C) 2015 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller containing a player view and basic playback controls.
*/

import Foundation
import AVFoundation
import UIKit
import MediaPlayer
/*
	KVO context used to differentiate KVO callbacks for this class versus other
	classes in its class hierarchy.
*/
private var playerViewControllerKVOContext = 0

class PlayerViewController: UIViewController {
    var showControl = false
    var didSetConstraints = false
    var startLocation:CGPoint = CGPointZero
    var volumeView: MPVolumeView = MPVolumeView()
    var volumeViewSlider: UISlider?{
        get{
            for view: UIView in volumeView.subviews {
                if (view.self.description.containsString("MPVolumeSlider")) {
                    return (view as! UISlider)
                }
            }
            return nil
        }
    }
   
    
    // MARK: Properties
    
    // Attempt load and test these asset keys before playing.
    static let assetKeysRequiredToPlay = [
        "playable",
        "hasProtectedContent"
    ]

	let player = AVPlayer()

	var currentTime: Double {
		get {
            return CMTimeGetSeconds(player.currentTime())
        }
		set {
            let newTime = CMTimeMakeWithSeconds(newValue, 1)
			player.seekToTime(newTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            
//            print("currentTime:\(newValue)")
        }
	}
    var currentVolume:Float{
        get{
            if let slider = volumeViewSlider{
                volumeSlider.value = slider.value
                
                return slider.value
            }
            return 0
        }
        set{
            if let slider = volumeViewSlider{
                volumeSlider.value = newValue
                slider.value = newValue
//                slider.sendActionsForControlEvents(.ValueChanged)
//                volumeSlider.sendActionsForControlEvents(.ValueChanged)
            }
        }
    }
    var currentBrightness:CGFloat{
        get{
            brightnessSlider.value = Float(UIScreen.mainScreen().brightness)
            return UIScreen.mainScreen().brightness
        }
        set{
            UIScreen.mainScreen().brightness = newValue
            brightnessSlider.value = Float(newValue)
        }
    }

	var duration: Double {
        guard let currentItem = player.currentItem else { return 0.0 }
        return CMTimeGetSeconds(currentItem.duration)
	}

	var rate: Float {
		get {
            return player.rate
        }

        set {
            player.rate = newValue
//            print("rate:\(newValue)")
        }
	}

    var asset: AVURLAsset? {
        didSet {
            guard let newAsset = asset else { return }

            asynchronouslyLoadURLAsset(newAsset)
        }
    }
    
	private var playerLayer: AVPlayerLayer? {
        return playerView.playerLayer
    }

    /*
        A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
        method.
    */
	private var timeObserverToken: AnyObject?

	private var playerItem: AVPlayerItem? = nil {
        didSet {
            /*
                If needed, configure player item here before associating it with a player.
                (example: adding outputs, setting text style rules, selecting media options)
            */
            player.replaceCurrentItemWithPlayerItem(self.playerItem)
        }
	}

    // MARK: - IBOutlets
    
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var brightnessSlider: UISlider!
 
    @IBOutlet weak var taggleVolumeBtn: UIButton!
    
    @IBOutlet weak var toggleBrightnessBtn: UIButton!
    @IBOutlet weak var volumeBoxView: UIView! {
        didSet {
           volumeBoxView.transform =  CGAffineTransformMakeRotation( CGFloat(-M_PI_2) );
        }
    }
    @IBOutlet weak var brightnessView: UIView!{
        didSet {
            brightnessView.transform =  CGAffineTransformMakeRotation( CGFloat(-M_PI_2) );
        }
    }
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var startTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
//    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
//    @IBOutlet weak var fastForwardButton: UIButton!
    @IBOutlet weak var playerView: PlayerView!
    
    @IBOutlet weak var controlbarView: UIView!
    // MARK: - View Controller
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
//        volumeView.hidden = true;
//        self.view .addSubview(volumeView)
        /*
            Update the UI when these player properties change.
        
            Use the context parameter to distinguish KVO for our particular observers 
            and not those destined for a subclass that also happens to be observing 
            these properties.
        */
        addObserver(self, forKeyPath: "player.currentItem.duration", options: [.New, .Initial], context: &playerViewControllerKVOContext)
        addObserver(self, forKeyPath: "player.rate", options: [.New, .Initial], context: &playerViewControllerKVOContext)
        addObserver(self, forKeyPath: "player.currentItem.status", options: [.New, .Initial], context: &playerViewControllerKVOContext)
        
        playerView.playerLayer.player = player
        
        let movieURL = NSBundle.mainBundle().URLForResource("jp3", withExtension: "mp4")!
//        let movieURL = NSURL(string: "http://192.168.130.109:90/jp3.mp4");
        asset = AVURLAsset(URL: movieURL, options: nil)
      
        
        // Make sure we don't have a strong reference cycle by only capturing self as weak.
        let interval = CMTimeMake(1, 1)
        timeObserverToken = player.addPeriodicTimeObserverForInterval(interval, queue: dispatch_get_main_queue()) {
            [weak self] time in
            self?.timeSlider.value = Float(CMTimeGetSeconds(time))
            if   let seconds = self?.timeSlider.value{
                let minus = Int(seconds/60);
                self?.startTimeLabel.text  = String(format:"%d:%02d", minus, Int(seconds % 60))
                
            }
            
        }
        //add pan
        let panRecognizer = UIPanGestureRecognizer(target: self, action: Selector("panedView:"))
        playerView.addGestureRecognizer(panRecognizer)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: Selector("tapedView:"))
        playerView.addGestureRecognizer(tapRecognizer)
        
    }
    override func updateViewConstraints() {
        if(!didSetConstraints){
            let h = volumeBoxView.frame.width/2 - volumeBoxView.frame.height/2
            self.view.addConstraint(NSLayoutConstraint(item: volumeBoxView, attribute: .Bottom, relatedBy: .Equal, toItem: controlbarView, attribute: .Top, multiplier: 1, constant: h))
            self.view.addConstraint(NSLayoutConstraint(item: volumeBoxView, attribute: .CenterX, relatedBy: .Equal, toItem: taggleVolumeBtn, attribute: .CenterX, multiplier: 1, constant: 0))
            
            self.view.addConstraint(NSLayoutConstraint(item: brightnessView, attribute: .Bottom, relatedBy: .Equal, toItem: controlbarView, attribute: .Top, multiplier: 1, constant: h))
            self.view.addConstraint(NSLayoutConstraint(item: brightnessView, attribute: .CenterX, relatedBy: .Equal, toItem: toggleBrightnessBtn, attribute: .CenterX, multiplier: 1, constant: 0))
        }

        
        super.updateViewConstraints();
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        player.pause()
        
        removeObserver(self, forKeyPath: "player.currentItem.duration", context: &playerViewControllerKVOContext)
        removeObserver(self, forKeyPath: "player.rate", context: &playerViewControllerKVOContext)
        removeObserver(self, forKeyPath: "player.currentItem.status", context: &playerViewControllerKVOContext)
    }
    
    // MARK: - Asset Loading

    func asynchronouslyLoadURLAsset(newAsset: AVURLAsset) {
        /*
            Using AVAsset now runs the risk of blocking the current thread (the 
            main UI thread) whilst I/O happens to populate the properties. It's
            prudent to defer our work until the properties we need have been loaded.
        */
        newAsset.loadValuesAsynchronouslyForKeys(PlayerViewController.assetKeysRequiredToPlay) {
            /*
                The asset invokes its completion handler on an arbitrary queue. 
                To avoid multiple threads using our internal state at the same time 
                we'll elect to use the main thread at all times, let's dispatch
                our handler to the main queue.
            */
            dispatch_async(dispatch_get_main_queue()) {
                /*
                    `self.asset` has already changed! No point continuing because
                    another `newAsset` will come along in a moment.
                */
                guard newAsset == self.asset else { return }

                /*
                    Test whether the values of each of the keys we need have been
                    successfully loaded.
                */
                for key in PlayerViewController.assetKeysRequiredToPlay {
                    var error: NSError?
                    
                    if newAsset.statusOfValueForKey(key, error: &error) == .Failed {
                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")

                        let message = String.localizedStringWithFormat(stringFormat, key)
                        
                        self.handleErrorWithMessage(message, error: error)
                        
                        return
                    }
                }
                
                // We can't play this asset.
                if !newAsset.playable || newAsset.hasProtectedContent {
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")
                    
                    self.handleErrorWithMessage(message)
                    
                    return
                }
                
                /*
                    We can play this asset. Create a new `AVPlayerItem` and make
                    it our player's current item.
                */
                self.playerItem = AVPlayerItem(asset: newAsset)
            }
        }
    }

    // MARK: - IBActions

    @IBAction func toggleVolumeSlide(sender: AnyObject) {
        volumeBoxView.hidden = !volumeBoxView.hidden
    }
    
    @IBAction func toggleBrightnessSlide(sender: UIButton) {
        brightnessView.hidden = !brightnessView.hidden
    }
	@IBAction func playPauseButtonWasPressed(sender: UIButton) {
        
		if player.rate != 1.0 {
            // Not playing forward, so play.
 			if currentTime == duration {
                // At end, so got back to begining.
				currentTime = 0.0
			}

			player.play()
		}
        else {
            // Playing, so pause.
			player.pause()
		}
	}
	
    func rewindButtonWasPressed(plus:Float) {
        // Rewind no faster than -2.0.
//        rate = max(player.rate - 2.0, -2.0)
        
//       let dxtime = Int(plus)/Int(self.view.frame.width) * Int(self.duration)
//        timeSlider.value =  max(Float(ctime),0)
//       
//        let (_,m,s) =  HudTools.shared.secondsToHoursMinutesSeconds(Int(currentTime))
//        let (_,m2,s2) =  HudTools.shared.secondsToHoursMinutesSeconds(Int(self.duration))
//        HudTools.shared.showBackward(self.view,msg:String(format: "[%d:%d/%d:%d]", arguments: [m,s,m2,s2]));
	}
	
	 func fastForwardButtonWasPressed() {
        // Fast forward no faster than 2.0.
//        rate = min(player.rate + 2.0, 2.0)
        timeSlider.value =  min(Float(timeSlider.value)+10,Float(duration))
      
        let (_,m,s) =  HudTools.shared.secondsToHoursMinutesSeconds(Int(currentTime))
        let (_,m2,s2) =  HudTools.shared.secondsToHoursMinutesSeconds(Int(self.duration))
        HudTools.shared.showForward(self.view,msg:String(format: "[%d:%d/%d:%d]", arguments: [m,s,m2,s2]));
	}

    @IBAction func timeSliderDidChange(sender: UISlider) {
        currentTime = Double(sender.value)
    }
    @IBAction func volumeSliderDidChange(sender: UISlider) {
        currentVolume = sender.value
    }
    
    @IBAction func brightnessSliderDidChange(sender: UISlider) {
        currentBrightness = CGFloat(sender.value)
    }
   
    // MARK: - KVO Observation

    // Update our UI when player or `player.currentItem` changes.
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        // Make sure the this KVO callback was intended for this view controller.
        guard context == &playerViewControllerKVOContext else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }

        if keyPath == "player.currentItem.duration" {
            // Update timeSlider and enable/disable controls when duration > 0.0

            /*
                Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when 
                `player.currentItem` is nil.
            */
            let newDuration: CMTime
            if let newDurationAsValue = change?[NSKeyValueChangeNewKey] as? NSValue {
                newDuration = newDurationAsValue.CMTimeValue
            }
            else {
                newDuration = kCMTimeZero
            }

            let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
            let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0

            timeSlider.maximumValue = Float(newDurationSeconds)

            timeSlider.value = hasValidDuration ? Float(CMTimeGetSeconds(player.currentTime())) : 0.0
            
//            rewindButton.enabled = hasValidDuration
            
            playPauseButton.enabled = hasValidDuration
            
//            fastForwardButton.enabled = hasValidDuration
            
            timeSlider.enabled = hasValidDuration
            
            startTimeLabel.enabled = hasValidDuration
            
            durationLabel.enabled = hasValidDuration
            
            // FIXME: Should use NSDateFormatter?
            let wholeMinutes = Int(trunc(newDurationSeconds / 60))

            durationLabel.text = String(format:"%d:%02d", wholeMinutes, Int(trunc(newDurationSeconds)) - wholeMinutes * 60)
        }
        else if keyPath == "player.rate" {
            // Update `playPauseButton` image.

            let newRate = (change?[NSKeyValueChangeNewKey] as! NSNumber).doubleValue
            
            let buttonImageName = newRate == 1.0 ? "PauseButton" : "PlayButton"
            
            let buttonImage = UIImage(named: buttonImageName)

            playPauseButton.setImage(buttonImage, forState: .Normal)
        }
        else if keyPath == "player.currentItem.status" {
            // Display an error if status becomes `.Failed`.

            /*
                Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
                `player.currentItem` is nil.
            */
            let newStatus: AVPlayerItemStatus

            if let newStatusAsNumber = change?[NSKeyValueChangeNewKey] as? NSNumber {
                newStatus = AVPlayerItemStatus(rawValue: newStatusAsNumber.integerValue)!
            }
            else {
                newStatus = .Unknown
            }
            
            if newStatus == .Failed {
                handleErrorWithMessage(player.currentItem?.error?.localizedDescription, error:player.currentItem?.error)
            }
        }
    }

    // Trigger KVO for anyone observing our properties affected by player and player.currentItem
    override class func keyPathsForValuesAffectingValueForKey(key: String) -> Set<String> {
        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "duration":     ["player.currentItem.duration"],
            "currentTime":  ["player.currentItem.currentTime"],
            "rate":         ["player.rate"]
        ]
        
        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValueForKey(key)
	}

    // MARK: - Error Handling

	func handleErrorWithMessage(message: String?, error: NSError? = nil) {
        NSLog("Error occured with message: \(message), error: \(error).")
    
        let alertTitle = NSLocalizedString("alert.error.title", comment: "Alert title for errors")
        let defaultAlertMessage = NSLocalizedString("error.default.description", comment: "Default error message when no NSError provided")

        let alert = UIAlertController(title: alertTitle, message: message == nil ? defaultAlertMessage : message, preferredStyle: UIAlertControllerStyle.Alert)

        let alertActionTitle = NSLocalizedString("alert.error.actions.OK", comment: "OK on error alert")

        let alertAction = UIAlertAction(title: alertActionTitle, style: .Default, handler: nil)
        
        alert.addAction(alertAction)

        presentViewController(alert, animated: true, completion: nil)
	}
    
    @IBOutlet weak var stopButton: UIButton!
    @IBAction func stopView(sender: UIButton) {
        player.replaceCurrentItemWithPlayerItem(nil)
       
    }
    func currentTimeAdd(plus:Float,_ end:Bool){
        let dxtime = Double(plus/50);// Double(plus)/Double(self.view.frame.width) * Double(self.duration)
        var ctime =  currentTime +  dxtime
//        print("plus:\(plus),dxtime:\(dxtime),currentTime:\(currentTime),duration:\(Double(self.duration))")
        
        ctime = ctime > duration ? duration : ctime
        ctime = ctime < 0 ? 0 :ctime
        
//        currentTime = ctime
        
        let (_,m,s) =  HudTools.shared.secondsToHoursMinutesSeconds(Int(ctime))
        let (_,m2,s2) =  HudTools.shared.secondsToHoursMinutesSeconds(Int(self.duration))
        if(plus>0){
            HudTools.shared.showForward(self.view,msg:String(format: "[%d:%d/%d:%d]", arguments: [m,s,m2,s2]));
        }else{
            HudTools.shared.showBackward(self.view,msg:String(format: "[%d:%d/%d:%d]", arguments: [m,s,m2,s2]));
        }
        if(end){
            timeSlider.value = Float(ctime)
            timeSlider.sendActionsForControlEvents(.ValueChanged)
        }
        
    }
    //调节音量
    func voiceAdd(plus:Float){
        
//        var volumeViewSlider: UISlider? = nil
//        for view: UIView in volumeView.subviews {
//            if (view.self.description.containsString("MPVolumeSlider")) {
//                volumeViewSlider = (view as! UISlider)
//            }
//        }
        // retrieve system volume
        if let slider = volumeViewSlider{
//            print(slider.value)
            // change system volume, the value is between 0.0f and 1.0f
            if (plus<0){
                currentVolume = slider.value+0.01
                 HudTools.shared.showVoice(self.view, msg: "音量:+0.01")
            } else{
                currentVolume = slider.value-0.01
                HudTools.shared.showVoice(self.view, msg: "音量:-0.01")
            }
            // send UI control event to make the change effect right now.
            
        }
    }
    func brightnessAdd(plus:Float){
        if(plus<0){
            UIScreen.mainScreen().brightness+=0.02;
           HudTools.shared.showBrightless(self.view, msg: "亮度:+0.02")
        }else{
            UIScreen.mainScreen().brightness-=0.02;
            HudTools.shared.showBrightless(self.view, msg: "亮度:-0.02")
        }
        
    }
     func tapedView(sender:UIPanGestureRecognizer){
        if(controlbarView.hidden){
            controlbarView.hidden =  false
            stopButton.hidden = false
        }else{
            controlbarView.hidden =  true
            stopButton.hidden = true
            brightnessView.hidden = true
            volumeBoxView.hidden = true
        }
    }
    func panedView(sender:UIPanGestureRecognizer){
        let stopLocation = sender.locationInView(self.view);
        let dx = stopLocation.x - startLocation.x;
        let dy = stopLocation.y - startLocation.y;
        if (sender.state == UIGestureRecognizerState.Began) {
            startLocation = sender.locationInView(self.view);
        }
        else if (sender.state == UIGestureRecognizerState.Changed) {
            if abs(dx)>abs(dy)   {
                currentTimeAdd(Float(dx),false)
            }else{
                if(stopLocation.x>playerView.bounds.width/2){
                    voiceAdd(Float(dy))
                }else{
                    brightnessAdd(Float(dy))
                }
            }
        }else if (sender.state == UIGestureRecognizerState.Ended) {
            if abs(dx)>abs(dy)   {
                currentTimeAdd(Float(dx),true)
            }
            SVProgressHUD.dismiss()
        }
    }
}