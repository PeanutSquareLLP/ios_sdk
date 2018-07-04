//
//  SparkThumbnails.swift
//  SparkPlayer
//
//  Created by alexeym on 05/04/2018.
//

import Foundation
import SparkLib

// XXX alexeym: work in progress
extension SparkPlayer: SparkThumbnailsDelegate {
    // XXX alexeym: move all activeController.sparkView.thumbnailView stuff to the SparkPlayerController class

    public func get_thumbnail_container() -> UIView! {
        return activeController.sparkView.thumbnailView
    }

    public func setWidth(_ width: NSNumber!, andHeight height: NSNumber!) {
        activeController.sparkView.thumbnailView.setSize(width.intValue, height.intValue)
    }

    public func display() {
        //activeController.sparkView.thumbnailView.isHidden = false
    }

    public func setPosition(_ position: NSNumber!) {

    }

    public func hide() {
        //activeController.sparkView.thumbnailView.isHidden = true
    }
}
