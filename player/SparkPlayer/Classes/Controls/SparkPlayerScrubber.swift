//
//  SparkPlayerScrubber.swift
//  SparkPlayer
//
//  Created by spark on 14/02/2018.
//

import UIKit
import AVFoundation

enum ThumbStates {
    case Normal
    case Focused
    case Highlighted
}

class SparkPlayerScrubber: UISlider {
    var loaded: [CMTimeRange]? {
        didSet {
            self.updateRanges()
        }
    }

    private var segments: [UIImageView] = []
    private var thumbState: ThumbStates = .Normal

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return true
    }

    func setup() {
        let thumb = UIImage.circle(diameter: 18, color: UIColor.SparkPlayer.thumb)
        self.setThumbImage(thumb, for: .normal)

        self.minimumTrackTintColor = UIColor.SparkPlayer.filled
        self.maximumTrackTintColor = UIColor.SparkPlayer.empty
    }

    func isThumbView(_ view: UIView) -> Bool {
        guard let image = view as? UIImageView else {
            return false
        }

        return image.image == self.currentThumbImage
    }

    func getThumbView() -> UIView? {
        return self.subviews.first { (view) -> Bool in
            if (view.subviews.count > 1) {
                return false
            }

            if (view.subviews.count == 0) {
                return isThumbView(view)
            }

            return isThumbView(view.subviews[0])
        }
    }

    func updateRanges() {
        guard let ranges = self.loaded else {
            return
        }

        // On time of viewWillAppear the slider's views are not ready
        if (self.subviews.count == 0) {
            return
        }

        let duration = CGFloat(self.maximumValue-self.minimumValue)
        let width = self.frame.width
        let widthPerSecond = width / duration
        // XXX alexeym TODO: add options for sizes to avoid hadrcoded values
        let height = self.maximumTrackImage(for: .normal)?.size.height ?? 2
        // XXX alexeym: find a better way to get vertical positioning
        let bar = self.subviews[0]
        let top = bar.frame.origin.y
        
        segments.forEach { (segment) in
            segment.removeFromSuperview()
        }
        segments.removeAll()
        ranges.forEach{(range) in
            let from = max(height, widthPerSecond *
                (CGFloat(range.start.seconds) - CGFloat(self.minimumValue)))
            let segmentWidth = widthPerSecond *
                min(CGFloat(range.duration.seconds), duration)
            let segmentWidthToUse: CGFloat
            if (from+segmentWidth > width-height) {
                segmentWidthToUse = width-from-height
            } else {
                segmentWidthToUse = segmentWidth
            }
            let segment = UIImageView()
            segment.backgroundColor = UIColor.SparkPlayer.loaded
            segment.frame.size = CGSize(width: segmentWidthToUse, height: height)
            segment.frame.origin = CGPoint(x: from, y: top)
            segments.append(segment)
            self.insertSubview(segment, aboveSubview: bar)
        }
    }

    func setThumbState(_ state: ThumbStates) {
        guard let thumb = getThumbView() else {
            return
        }

        let scale: CGAffineTransform
        let duration: TimeInterval

        switch state {
        case .Normal:
            scale = CGAffineTransform(scaleX: 0.01, y: 0.01)
            duration = 0.5
        case .Focused:
            scale = CGAffineTransform(scaleX: 2/3, y: 2/3)
            duration = thumbState == .Normal ? 0.2 : 0
        case .Highlighted:
            scale = CGAffineTransform(scaleX: 1, y: 1)
            duration = thumbState == .Normal ? 0.2 : 0
        }

        thumbState = state
        thumb.layer.removeAllAnimations()

        if (duration == 0) {
            thumb.transform = scale
        } else {
            UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: {
                thumb.transform = scale
            }, completion: nil)
        }
    }
}

