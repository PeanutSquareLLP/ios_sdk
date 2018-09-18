//
//  SparkPlayerInternalDelegate.swift
//  SparkPlayer
//
//  Created by alexeym on 05/04/2018.
//

import AVKit

protocol SparkPlayerInternalDelegate {
    // controls handlers
    func onPlayClick()
    func onFullscreenClick()

    // Internal interface for AVPlayer data
    func isLiveStream() -> Bool
    func isDvrEnabled() -> Bool
    func currentTime() -> CMTime
    func seekStart(_ value: CMTime)
    func seekTo(_ value: CMTime)
    func seekMove(_ value: CMTime)
    func canPlayFastForward() -> Bool
    func canPlaySlowForward() -> Bool
    func getRate() -> Float
    func setRate(_ rate: Float)
    func duration() -> CMTime
    func loadedTimeRanges() -> [CMTimeRange]
    func seekableTimeRanges() -> [CMTimeRange]
    func isPaused() -> Bool
    func isEnded() -> Bool
    func isSeeking() -> Bool
    func getBitrate() -> Double
    func getURL() -> String?
    func getCurrentURL() -> String?
    func getQualityList() -> [HolaHLSLevelInfo]
    func setQuality(withURL url: String?) throws

    // Ad interface for Googima
    func isAdPlaying() -> Bool
    func onAdStarted()
    func onAdCompleted()
}

extension SparkPlayer: SparkPlayerInternalDelegate {
    func onPlayClick() {
        guard let player = self.player else {
            return
        }

        if (player.rate == 0) {
            if (isEnded()) {
                player.seek(to: kCMTimeZero)
            }
            player.rate = _rate
        } else {
            player.pause()
        }
    }

    func onFullscreenClick() {
        setFullscreen(!self.fullscreen, source: "user")
    }

    func isLiveStream() -> Bool {
        return player?.currentItem?.status == .readyToPlay && player?.currentItem?.duration.isIndefinite == true
    }
    
    func isDvrEnabled() -> Bool {
        let ranges = seekableTimeRanges()
        guard minDvrLength>0 && ranges.count>0 else { return false }
        return ranges[0].duration.seconds>Double(minDvrLength)
    }

    func currentTime() -> CMTime {
        guard let player = self.player else {
            return CMTimeMakeWithSeconds(0, 1)
        }

        return player.currentTime()
    }

    func isEnded() -> Bool {
        guard
            let player = self.player,
            let item = self.player?.currentItem else
        {
            return false
        }

        return player.rate == 0 && item.currentTime() >= item.duration
    }

    func seekStart(_ value: CMTime) {
        guard let handler = thumbnailsHandler else {
            return
        }

        handler.seekStart(value)
    }

    func seekTo(_ value: CMTime) {
        seeking = true
        sparkProxy?.on_seeking()
        player?.seek(to: value, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
    }

    func seekMove(_ value: CMTime) {
        guard let handler = thumbnailsHandler else {
            return
        }

        handler.seekMove(value)
    }

    func onSeeked() {
        if let handler = thumbnailsHandler {
            handler.seekEnd()
        }

        seeking = false
        sparkProxy?.on_seeked()
    }

    func isSeeking() -> Bool {
        return seeking
    }

    func canPlayFastForward() -> Bool {
        return player?.currentItem?.canPlayFastForward ?? false
    }

    func canPlaySlowForward() -> Bool {
        return player?.currentItem?.canPlaySlowForward ?? false
    }

    func getRate() -> Float {
        return isPaused() ? _rate : (player?.rate ?? _rate)
    }

    func setRate(_ rate: Float) {
        _rate = rate
        if (!isPaused()) {
            player?.rate = _rate
        }
    }

    func duration() -> CMTime {
        guard let item = self.player?.currentItem else {
            return CMTimeMakeWithSeconds(0, 1)
        }

        return item.duration.isIndefinite ? CMTimeMakeWithSeconds(0, 1) : item.duration
    }

    func loadedTimeRanges() -> [CMTimeRange] {
        guard let item = self.player?.currentItem else {
            return []
        }

        return item.loadedTimeRanges.asTimeRanges
    }
    
    func seekableTimeRanges() -> [CMTimeRange] {
        guard let item = self.player?.currentItem else {
            return []
        }
        
        return item.seekableTimeRanges.asTimeRanges
    }

    func isPaused() -> Bool {
        guard let player = self.player else {
            return true
        }

        return player.rate == 0
    }

    func onPlay() {
        paused = false
        activeController.onPlayPause()
        activeController.activateView()
        sparkProxy?.on_play()
    }

    func onPaused() {
        paused = true
        activeController.onPlayPause()
        activeController.activateView()
        // player will fire ended > pause in that order, avoid extra pause
        if (!isEnded()) {
            sparkProxy?.on_pause()
        }
    }

    func isAdPlaying() -> Bool {
        guard let ima = plugins[GoogimaPlugin.name] as? GoogimaPlugin else {
            return false
        }
        return ima.isAdPlaying()
    }
    
    func onAdStarted() {
        sparkProxy?.on_ad_suspend()
    }
    
    func onAdCompleted() {
        sparkProxy?.on_ad_restore()
    }

    func getCurrentURL() -> String? {
        guard let asset = player?.currentItem?.asset as? AVURLAsset else {
            return nil
        }

        return asset.url.absoluteString
    }

    func getURL() -> String? {
        guard let asset = player?.currentItem?.asset as? AVURLAsset else {
            return nil
        }

        guard let sparkAsset = asset as? SparkPlayerHLSAsset else {
            return asset.url.absoluteString
        }

        return sparkAsset.getOriginURL()
    }

    func getBitrate() -> Double {
        guard
            let logs = player?.currentItem?.accessLog(),
            let lastEntry = logs.events.last
        else {
            return 0
        }

        return lastEntry.indicatedBitrate < 0 ? round(lastEntry.observedBitrate) : lastEntry.indicatedBitrate
    }

    func getQualityList() -> [HolaHLSLevelInfo] {
        guard let asset = player?.currentItem?.asset as? SparkPlayerHLSAsset else {
            return []
        }

        return asset.getLevels()
    }

    func setQuality(withURL url: String? = nil) throws {
        guard let asset = player?.currentItem?.asset as? SparkPlayerHLSAsset else {
            throw SparkPlayerAssetError.NotASparkAsset
        }

        if let newAsset = asset.getQualityAsset(forURL: url) {
            let isPaused = self.isPaused()
            player?.pause()

            let currentTime = self.currentTime()

            let newItem = AVPlayerItem(asset: newAsset)
            player?.replaceCurrentItem(with: newItem)

            self.seekTo(currentTime)

            if (!isPaused) {
                player?.rate = _rate
            }
        }
    }
}
