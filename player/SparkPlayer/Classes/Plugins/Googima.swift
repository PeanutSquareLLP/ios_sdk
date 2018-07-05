import GoogleInteractiveMediaAds

class GoogimaPlugin: NSObject, PluginInterface, IMAAdsLoaderDelegate, IMAAdsManagerDelegate {
    static var name: String! { return "googima" }
    static private var observerContext = 0
    private var _config: Dictionary<String, Any>!
    private var _player: SparkPlayerDelegate!
    private var _viewController: UIViewController!
    private var _contentPlayer: AVPlayer?
    private var _contentItem: AVPlayerItem?
    private var _contentPlayhead: IMAAVPlayerContentPlayhead?
    private var _adsLoader: IMAAdsLoader!
    private var _adsManager: IMAAdsManager!
    private var _pendingAdRequest = false
    private var _adInProgress = false
    
    required init(config: Dictionary<String, Any>!, player: SparkPlayerDelegate) {
        super.init()
        _config = config
        _player = player
        _adsLoader = IMAAdsLoader(settings: nil)
        _adsLoader.delegate = self
    }
    
    func onViewReady(controller: UIViewController!) {
        self._viewController = controller
        _requestAds()
    }
    
    func onPlayerItemChange(player: AVPlayer?, item: AVPlayerItem?) {
        if (player != _contentPlayer) {
            _playerDetach()
            _contentPlayer = player
            _contentItem = nil
            _playerAttach()
        }
        if (_contentPlayer == nil) {
            return
        }
        if (item != _contentItem) {
            _contentItem = item
        }
        if (_contentItem == nil) {
            return
        }
        _pendingAdRequest = true
        _requestAds()
    }
    
    func onVideoEnded() -> Void {
        _adsLoader.contentComplete()
    }
    
    func isAdPlaying() -> Bool {
        return _adInProgress
    }
    
    private func _playerAttach() {
        if (_contentPlayer==nil) {
            return
        }
        _contentPlayhead = IMAAVPlayerContentPlayhead(avPlayer: _contentPlayer)
        _contentPlayer?.addObserver(self, forKeyPath: "rate",
            options: NSKeyValueObservingOptions.new,
            context: &GoogimaPlugin.observerContext)
    }
    
    private func _playerDetach() {
        if (_contentPlayer==nil) {
            return
        }
        _contentPlayer?.removeObserver(self, forKeyPath: "rate",
            context: &GoogimaPlugin.observerContext)
        _contentPlayhead = nil
    }
    
    public override func observeValue(forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?)
    {
        if (context != &GoogimaPlugin.observerContext) {
            super.observeValue(forKeyPath: keyPath, of: object, change: change,
                context: context)
            return
        }
        if let key = keyPath, object != nil {
            switch key {
            case "rate":
                _requestAds()
                break
            default: break
            }
        }
    }
    
    private func _requestAds() {
        let rate = _contentPlayer?.rate ?? 0
        if (_viewController==nil || !_pendingAdRequest || rate<=0) {
            return
        }
        _pendingAdRequest = false
        // Create ad display container for ad rendering.
        let adDisplayContainer = IMAAdDisplayContainer(
            adContainer: _viewController.view,
            companionSlots: nil)
        // Create an ad request with our ad tag, display container, and optional user context.
        let request = IMAAdsRequest(
            adTagUrl: _config["adTagUrl"] as? String,
            adDisplayContainer: adDisplayContainer,
            contentPlayhead: _contentPlayhead,
            userContext: nil)
        _adsLoader.requestAds(with: request)
    }
    
    // MARK: - IMAAdsLoaderDelegate
    
    public func adsLoader(_ loader: IMAAdsLoader!, adsLoadedWith adsLoadedData: IMAAdsLoadedData!) {
        // Grab the instance of the IMAAdsManager and set ourselves as the delegate.
        _adsManager = adsLoadedData.adsManager
        _adsManager.delegate = self
        // Create ads rendering settings and tell the SDK to use the in-app browser.
        let adsRenderingSettings = IMAAdsRenderingSettings()
        adsRenderingSettings.webOpenerPresentingController = _viewController
        // Initialize the ads manager.
        _adsManager.initialize(with: adsRenderingSettings)
    }
    
    public func adsLoader(_ loader: IMAAdsLoader!, failedWith adErrorData: IMAAdLoadingErrorData!) {
        print("[googima] error loading ads: \(adErrorData.adError.message)")
        _contentPlayer?.play()
    }
    
    // MARK: - IMAAdsManagerDelegate
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive event: IMAAdEvent!) {
        print("[googima] ads manager event: \(event.typeString!)")
        switch (event.type) {
        case IMAAdEventType.LOADED:
            _adsManager.start()
            break
        case IMAAdEventType.STARTED:
            if (!_adInProgress)
            {
                _adInProgress = true
                _player.onAdStarted()
            }
            break
        case IMAAdEventType.SKIPPED: fallthrough
        case IMAAdEventType.COMPLETE:
            if (_adInProgress)
            {
                _adInProgress = false
                _player.onAdCompleted()
            }
            break
        default:
            break
        }
    }
    
    public func adsManager(_ adsManager: IMAAdsManager!, didReceive error: IMAAdError!) {
        // Something went wrong with the ads manager after ads were loaded.
        // Log the error and play the content.
        print("[googima] ads manager error: \(error.message)")
        _contentPlayer?.play()
    }
    
    public func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager!) {
        // The SDK is going to play ads, so pause the content.
        _contentPlayer?.pause()
    }
    
    public func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager!) {
        // The SDK is done playing ads (at least for now), so resume the content.
        _contentPlayer?.play()
    }
}
