//
//  SparkThumbnailView.swift
//  SparkPlayer
//
//  Created by norlin on 16/03/2018.
//

import UIKit

class SparkThumbnailView: UIView {
    @IBOutlet var imageView: UIImageView!

    @IBOutlet var height: NSLayoutConstraint!
    @IBOutlet var width: NSLayoutConstraint!
    @IBOutlet var left: NSLayoutConstraint!

    func setImage(_ image: UIImage) {
        /*let (w, h) = (image.size.width, image.size.height)
        let aspectRation = w / h

        if (aspectRation < 0) {
            width.constant = image.size.width
            height.constant = image.size.width / aspectRation
        } else {
            height.constant = image.size.height
            width.constant = image.size.height * aspectRation
        }*/

        imageView.image = image
    }

    func setPosition(_ position: CGFloat) {
        let left = position.isFinite ? position : 0
        self.left.constant = left - frame.width / 2
    }

    func setSize(_ width: Int, _ height: Int) {
        self.width.constant = CGFloat(width)
        self.height.constant = CGFloat(height)
    }
}
