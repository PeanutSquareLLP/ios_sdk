//
//  ViewController.swift
//  demo
//
//  Created by deploy on 25/01/2018.
//  Copyright © 2018 holaspark. All rights reserved.
//

import UIKit
import UserNotifications
import MobileCoreServices
import SparkPlayer
import AVFoundation
import SparkLib

let NOTIFICATION_DELAY = 10
let AD_TAG = "https://pubads.g.doubleclick.net/gampad/ads?sz=640x480&iu=/124319096/external/single_ad_samples&ciu_szs=300x250&impl=s&gdfp_req=1&env=vp&output=vast&unviewed_position_start=1&cust_params=deployment%3Ddevsite%26sample_ct%3Dskippablelinear&correlator="

struct VideoPage {
    var video: VideoItem
    var text: String
}

class ViewController: UIViewController, SparkPlayerDelegate {

    // MARK: Properties
    @IBOutlet weak var generateNotificationButton: UIButton!
    @IBOutlet weak var playerContainer: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!

    var customerID: String!
    var info: VideoPage!
    var videoDescription: String!

    var sparkPlayer: SparkPlayer!

    // MARK: Actions
    @IBAction func onGenerateNotification(sender: UIButton){
        guard sender.isEnabled else { return }
        sender.setTitle("loading attachment", for: UIControlState.disabled)
        sender.isEnabled = false
        // using the same customer
        let api = SparkAPI.getAPI(nil)
        api.sendPreviewNotification(
            info.video.getUrl(),
            withTitle: "Watch",
            withSubtitle: nil,
            withBody: info.video.getTitle(),
            withTriggerOn: UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(NOTIFICATION_DELAY),
                repeats: false),
            withBeforeSend: { (content, settings) -> Bool in
                print("preview successfully loaded");
                // add custom user-info to use in notification response handler
                let info = NSMutableDictionary(dictionary: content.userInfo)
                info.setValue("vid12345", forKey: "custom-video-id")
                content.userInfo = info as! [AnyHashable : Any];
                // change notification sound
                if (settings.soundSetting == .enabled) {
                    content.sound = UNNotificationSound.default();
                }
                return true
            },
            withCompletionBlock: { (error) in
                if (error != nil) {
                    print("notification request failed with error=\(error!)")
                }
                DispatchQueue.main.async {
                    let hint = error != nil ? "scheduling failed" :
                        "notification sent (wait \(NOTIFICATION_DELAY) sec)"
                    sender.setTitle(hint, for: UIControlState.disabled)
                    if (error != nil) {
                        self.descriptionLabel.text =
                            "Failure details: \(error!)"
                    }
                }
                DispatchQueue.main.asyncAfter(
                    deadline: .now()+TimeInterval(NOTIFICATION_DELAY))
                {
                    sender.isEnabled = true
                    self.descriptionLabel.text = self.info.text
                }
            })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sparkPlayer = SparkPlayer(withConfig: [
            "googima": ["adTagUrl": AD_TAG]
        ])
        sparkPlayer.delegate = self
        sparkPlayer.player = AVPlayer(url: info.video.getUrl())
        sparkPlayer.view.frame.origin = CGPoint.zero
        sparkPlayer.view.frame.size = playerContainer.frame.size
        
        playerContainer.addSubview(sparkPlayer.view)
        self.addChildViewController(sparkPlayer)

        self.title = info.video.getTitle()
        self.descriptionLabel.text = info.text
        print("selected video url: \(info.video.getUrl())")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // XXX alexeym: hack to disable swipe-to-back gesture which
        // conflicting with video slider moving from the left position
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if (self.isMovingFromParentViewController) {
            sparkPlayer.player?.pause()
            sparkPlayer.player?.replaceCurrentItem(with: nil)
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
    
    // SparkPlayerDelegate
    
    func onReady(_ sparkPlayer: SparkPlayer) {
        print("player is ready")
    }
    
    func onFullscreenChange(_ sparkPlayer: SparkPlayer, state: Bool,
        source: String)
    {
        print("fullscreen \(state ? "enabled" : "disabled") by \(source)");
    }

}




