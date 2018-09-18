//
//  SparkPlayerView.swift
//  SparkPlayer
//
//  Created by spark on 13/02/2018.
//

import UIKit
import SparkLib

enum FadeDirection {
    case In
    case Out
}
enum VideoMode {
    case VOD
    case LIVE
    case DVR
    case DVR_LIVE
}

class SparkPlayerView: UIView {
    @IBOutlet weak var fullscreenButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!

    @IBOutlet weak var skipBackButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var skipNextButton: UIButton!

    @IBOutlet weak var liveDot: UIImageView!
    @IBOutlet weak var liveLabel: UILabel!
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!

    @IBOutlet weak var positionSlider: SparkPlayerScrubber!

    @IBOutlet weak var currentTimeWidth: NSLayoutConstraint!
    @IBOutlet weak var durationWidth: NSLayoutConstraint!
    @IBOutlet var sliderRight: NSLayoutConstraint!
    @IBOutlet var sliderBottom: NSLayoutConstraint!
    @IBOutlet var sliderLeft: NSLayoutConstraint!
    @IBOutlet var sliderTop: NSLayoutConstraint!

    @IBOutlet var thumbnailView: SparkThumbnailView!

    var controls: [UIView] {
        get {
            return [
                skipBackButton,
                playButton,
                skipNextButton,
                liveDot,
                liveLabel,
                currentTimeLabel,
                durationLabel,
                fullscreenButton,
                moreButton
            ] + (isFullscreen ? [
                positionSlider
            ] : [])
        }
    }

    private var isFullscreen: Bool = false
    private var videoMode: VideoMode = .VOD
    var controlsBackground: CAGradientLayer!

    func setup() {
        controlsBackground = CAGradientLayer()
        let baseColor = UIColor.SparkPlayer.fade
        let edgeColor = baseColor.cgColor
        let centerColor = baseColor.withAlphaComponent(0.1).cgColor
        controlsBackground.colors = [edgeColor, centerColor, centerColor, edgeColor]
        controlsBackground.locations = [0, 0.35, 0.65, 1]

        self.layer.insertSublayer(controlsBackground, at: 0)

        thumbnailView.isHidden = true

        skipBackButton.isHidden = true
        skipNextButton.isHidden = true
    }

    func setFullscreen(_ fullscreen: Bool) {
        sliderRight.isActive = !fullscreen
        sliderBottom.isActive = !fullscreen
        sliderLeft.isActive = !fullscreen
        sliderTop.isActive = !fullscreen

        isFullscreen = fullscreen

        layoutIfNeeded()
    }

    func fade(_ direction: FadeDirection) {
        let duration: TimeInterval
        let alpha: CGFloat

        switch direction {
        case .In:
            duration = 0.2
            alpha = 1
        case .Out:
            duration = 1
            alpha = 0
        }

        self.layer.removeAllAnimations()

        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
            self.controls.forEach({ (control) in
                control.alpha = alpha
            })
            self.controlsBackground.opacity = Float(alpha)
        }, completion: nil)
    }

    func getVideoMode() -> VideoMode {
        return self.videoMode
    }
    func setVideoMode(_ mode: VideoMode) {
        guard videoMode != mode else { return }
        videoMode = mode
        updateControls()
    }
    
    func updateControls() {
        if (videoMode != .VOD) {
            let height = liveDot.frame.height
            let color = videoMode == .LIVE || videoMode == .DVR_LIVE ?
                UIColor.SparkPlayer.thumb : UIColor.SparkPlayer.loaded
            liveDot.image = UIImage.circle(diameter: height, color: color)
        }
        currentTimeLabel.isHidden = videoMode != .VOD
        liveDot.isHidden = videoMode == .VOD
        liveLabel.isHidden = videoMode == .VOD
        durationLabel.isHidden = videoMode == .LIVE || videoMode == .DVR_LIVE
        positionSlider.isHidden = videoMode == .LIVE
        positionSlider.isEnabled = videoMode != .LIVE
    }
}

// Handle Spark features
extension SparkPlayerView {
    func updateThumbnail(withImage image: UIImage? = nil) {
        guard !thumbnailView.isHidden else {
            return
        }

        if let image = image {
            thumbnailView.setImage(image)
        }

        let width = positionSlider.frame.width
        let percent = CGFloat(positionSlider.value / positionSlider.maximumValue)

        thumbnailView.setPosition(width * percent)
    }
}
