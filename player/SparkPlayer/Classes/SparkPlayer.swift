//
//  SparkPlayer.swift
//  SparkPlayer
//
//  Created by spark on 12/02/2018.
//

import AVKit
import SparkLib

public class SparkPlayer: UIViewController {
    private static var observerContext = 0

    static func getResourceBundle() -> Bundle? {
        let bundle = Bundle(for: SparkPlayer.self)
        guard let bundleURL = bundle.url(forResource: "SparkPlayer", withExtension: "bundle") else {
            return nil
        }
        guard let resourceBundle = Bundle(url: bundleURL) else {
            return nil
        }

        return resourceBundle
    }

    // player handling
    private var config: Dictionary<String, Any>!
    private var playerLayer: AVPlayerLayer!
    private var timeObserverToken: Any?
    private var ready = false
    internal var plugins: Dictionary<String, PluginInterface>!
    internal var paused = true
    internal var _rate: Float = 1
    internal var seeking = false
    private weak var currentItem: AVPlayerItem? {
        willSet {
            unbindCurrentItem()
        }
        didSet {
            bindCurrentItem()
        }
    }

    // views handling
    internal var inlineController: SparkPlayerInlineController!
    internal var fullscreenController: SparkPlayerFullscreenController!
    internal var fullscreen = false
    internal var inlineFrame: CGRect?

    // Spark handling
    var sparkAPI: SparkAPI? {
        return SparkAPI.getAPI(nil)
    }

    // Thumbnails
    var thumbnailsHandler: SparkThumbnailsHandlerDelegate? = nil

    var sparkProxy: SparkLibJSDelegate?

    public var player: AVPlayer? {
        willSet {
            unbindPlayerEvents()
        }
        didSet {
            setup()
        }
    }

    var activeController: SparkPlayerController {
        get {
            return fullscreen ? fullscreenController : inlineController
        }
    }

    public var allowAutoFullscreen = true
    public var minDvrLength = 10*60
    public var limitControlsWidth = false
    public var delegate: SparkPlayerDelegate?
    
    func getAPI(forCustomer id: String? = nil) {

    }

    public override func viewDidLoad() {
        view.backgroundColor = UIColor.black

        playerLayer = AVPlayerLayer()
        if let player = self.player {
            playerLayer.player = player
        }

        inlineController = SparkPlayerInlineController()
        inlineController.delegate = self
        inlineController.playerLayer = playerLayer

        fullscreenController = SparkPlayerFullscreenController()
        fullscreenController.delegate = self

        // XXX alexeym TODO: fix transition animation
        //fullscreenController.transitioningDelegate = self

        view.autoresizesSubviews = true

        self.addChildViewController(inlineController)
        view.addSubview(inlineController.view)

        NotificationCenter.default.addObserver(self, selector: #selector(SparkPlayer.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        notifyPlugins(event: "viewChange")
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        if (!ready)
        {
            ready = true
            self.delegate?.onReady?(self)
        }
    }

    convenience public init() { self.init(withConfig: nil) }
    
    public init(withConfig config: Dictionary<String, Any>?) {
        super.init(nibName: nil, bundle: nil)
        self.config = config ?? Dictionary<String, Any>()
        if let allowAutoFullscreen = self.config["allowAutoFullscreen"] as? Bool {
            self.allowAutoFullscreen = allowAutoFullscreen
        }
        if let minDvrLength = self.config["minDvrLength"] as? Int {
            self.minDvrLength = minDvrLength
        }
        self.plugins = Dictionary<String, PluginInterface>()
        if let cfg = self.config[GoogimaPlugin.name] as? Dictionary<String, Any> {
            self.plugins[GoogimaPlugin.name] =
	        GoogimaPlugin(config: cfg, player: self)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let width:CGFloat

        if (limitControlsWidth && playerLayer.videoRect.width > 0) {
            width = min(view.frame.width, playerLayer.videoRect.width)
        } else {
            width = view.frame.width
        }

        inlineController.view.frame.size = CGSize(width: width, height: view.frame.height)
        inlineController.view.center = view.center
    }

    @objc func rotated() {
        if (!allowAutoFullscreen || !UIDevice.current.orientation.isValidInterfaceOrientation || UIDevice.current.orientation == .portraitUpsideDown) {
            return
        }

        let topViewController = self.topMostViewController()
        if (!topViewController.shouldAutorotate) {
            return
        }

        if (UIDevice.current.orientation.isLandscape) {
            setFullscreen(true, source: "orientationchange")
        } else {
            setFullscreen(false, source: "orientationchange")
        }
    }

    func setup() {
        if let layer = self.playerLayer {
            layer.player = self.player
        }

        guard self.player != nil else {
            return
        }

        bindPlayerEvents()
    }

    func setFullscreen(_ fullscreen: Bool, source: String) {
        if (self.fullscreen == fullscreen) {
            return
        }

        if (fullscreen) {
            fullscreenController.isFullscreen = true
            self.present(fullscreenController, animated: true, completion: nil)
            fullscreenController.playerLayer = playerLayer
            fullscreenController.sparkView.setFullscreen(true)
        } else {
            fullscreenController.sparkView.setFullscreen(false)
            fullscreenController.isFullscreen = false
            fullscreenController.dismiss(animated: true, completion: nil)
            inlineController.playerLayer = playerLayer
        }

        self.fullscreen = fullscreen
        notifyPlugins(event: "viewChange")
	self.delegate?.onFullscreenChange?(self, state: self.fullscreen,
            source: source)
    }

    func onTransitionEnded() {

    }


    func bindPlayerEvents() {
        guard let player = self.player else {
            return
        }

        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(1, 1), queue: DispatchQueue.main) { (time) -> Void in
            self.activeController.timeupdate()
            self.sparkProxy?.on_timeupdate(NSNumber(value: time.seconds))
        }

        if let item = player.currentItem {
            handlePlayerItem(item)
        }

        player.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.new, context: &SparkPlayer.observerContext)
        player.addObserver(self, forKeyPath: "currentItem", options: NSKeyValueObservingOptions.new, context: &SparkPlayer.observerContext)
    }

    func unbindPlayerEvents() {
        currentItem = nil

        guard let player = self.player else {
            return
        }

        if let token = self.timeObserverToken {
            player.removeTimeObserver(token)
        }

        player.removeObserver(self, forKeyPath: "rate")
        player.removeObserver(self, forKeyPath: "currentItem")
    }

    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let key = keyPath, context == &SparkPlayer.observerContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if let player = object as? AVPlayer {
            switch key {
            case "rate":
                if (player.rate == 0) {
                    onPaused()
                } else if (paused) {
                    onPlay()
                }
            case "currentItem":
                if let newItem = player.currentItem {
                    if let _ = newItem.asset as? SparkPlayerHLSAsset {
                        // do not do anything if we're switching to own item
                        return
                    }

                    handlePlayerItem(newItem)
                } else {
                    currentItem = nil
                }
            default:
                return
            }
        }

        if let item = object as? AVPlayerItem {
            switch key {
            case "status":
                if (seeking == true && item.status == .readyToPlay) {
                    onSeeked();
                }
            default:
                return
            }
        }
    }

    func handlePlayerItem(_ item: AVPlayerItem) {
        guard let asset = item.asset as? AVURLAsset else {
            print("AVURLAsset is required")
            currentItem = item
            return
        }

        let sparkAsset = SparkPlayerHLSAsset(url: asset.url, options:[
            AVURLAssetPreferPreciseDurationAndTimingKey: true,
        ])
        let sparkItem = AVPlayerItem(asset: sparkAsset)

        currentItem = sparkItem

        player?.replaceCurrentItem(with: sparkItem)
    }

    func bindCurrentItem() {
        guard let item = currentItem else {
            notifyPlugins(event: "playerItemChange");
            return
        }

        // XXX alexeym: disabled, work in progress
        //if (false) {
        sparkProxy = sparkAPI?.addPlayerProxy(item, andPlayer: self)
        //}
        item.addObserver(self, forKeyPath: "status",
            options: NSKeyValueObservingOptions.new,
            context: &SparkPlayer.observerContext)
        NotificationCenter.default.addObserver(self,
            selector: #selector(SparkPlayer.contentDidFinishPlaying(_:)),
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: item)
        notifyPlugins(event: "playerItemChange");
    }

    func unbindCurrentItem() {
        guard let item = currentItem else {
            return
        }

        // XXX alexeym: disabled, work in progress
        //if (false) {
        sparkProxy = nil
        sparkAPI?.removePlayerProxy(item)
        //}
        item.removeObserver(self, forKeyPath: "status", context: &SparkPlayer.observerContext)
        NotificationCenter.default.removeObserver(self,
            name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
            object: item)
    }
    
    @objc func contentDidFinishPlaying(_ notification: Notification) {
        if (notification.object as? AVPlayerItem) != currentItem {
            return
        }
        notifyPlugins(event: "videoEnded")
        self.sparkProxy?.on_ended()
    }
    
    func notifyPlugins(event: String!) {
        self.plugins.values.forEach { (plugin) in
            switch (event) {
            case "viewChange":
                plugin.onViewChange(view: activeController.view)
                break
            case "playerItemChange":
                plugin.onPlayerItemChange(player: player, item: currentItem)
                break
            case "videoEnded":
                plugin.onVideoEnded()
                break
            default: break
            }
        }
    }

}

// public API
public extension SparkPlayer {
    func isFullscreen() -> Bool {
        return self.fullscreen
    }
    func isLive() -> Bool {
        return self.isLiveStream()
    }
    func isPlaying() -> Bool {
        return !self.isPaused()
    }
    func isAdActive() -> Bool {
        return self.isAdPlaying()
    }
    func getCurrentTime() -> CMTime {
        return self.currentTime()
    }
    func getCurrentSrc() -> String? {
        return self.getCurrentURL()
    }
    func getDuration() -> CMTime {
        return self.duration()
    }
    func setFullscreen(_ fullscreen: Bool) {
        setFullscreen(fullscreen, source: "api")
    }
}
