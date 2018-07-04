//
//  SparkLibPlayerDelegate.swift
//  spark-demo
//
//  Created by volodymyr on 06/04/2018.
//

import SparkLib

extension SparkPlayer: SparkLibPlayerDelegate {
    
    public func get_origin_url(_ url: URL!) -> URL! {
        guard let url = url else {
            return nil
        }
        return HolaHLSParser.applyOriginScheme(url)
    }
    
    public func get_thumbnails_delegate(_ handler: SparkThumbnailsHandlerDelegate!) -> SparkThumbnailsDelegate! {
        thumbnailsHandler = handler
        return self
    }
    
    public func is_ad_playing() -> CBool {
        return isAdPlaying()
    }
    
    public func is_live() -> CBool {
        return isLive()
    }
    
    public func is_paused() -> CBool {
        return isPaused()
    }
    
    public func is_ended() -> CBool {
        return isEnded()
    }
}
