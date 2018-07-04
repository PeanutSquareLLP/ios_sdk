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
    private var isLive: Bool = false
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

    func setLive(_ live: Bool) {
        guard self.isLive != live else {
            return
        }

        self.isLive = live

        if (live && liveDot.image == nil) {
            let height = liveDot.frame.height
            liveDot.image = UIImage.circle(diameter: height, color: UIColor.SparkPlayer.thumb)
        }

        currentTimeLabel.isHidden = live
        liveDot.isHidden = !live
        liveLabel.isHidden = !live
        durationLabel.isHidden = live
        positionSlider.isHidden = live
        positionSlider.isEnabled = !live
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
