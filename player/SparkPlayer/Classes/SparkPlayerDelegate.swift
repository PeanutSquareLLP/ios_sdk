// Player delegate for external subscriber (player owner)
@objc public protocol SparkPlayerDelegate {    

    // Called on first viewDidAppear of SparkPlayer
    @objc optional func onReady(_ sparkPlayer: SparkPlayer)

    // Called on fullscreen state change
    //     @param state - updated fullscreen state
    //     @param source - entity that initiated a change, possible values:
    //         * "user" - user tapped on fullscreen button
    //         * "orientationchange" - caused by device orientation change
    //           (only when sparkPlayer.allowAutoFullscreen is true)
    //         * "api" - invoked programmatically using player api
    @objc optional func onFullscreenChange(_ sparkPlayer: SparkPlayer,
        state: Bool, source: String)
}
