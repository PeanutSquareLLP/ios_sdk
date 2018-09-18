//
//  SparkPlayerController.swift
//  SparkPlayer
//
//  Created by spark on 13/02/2018.
//

import AVKit

class SparkPlayerController: UIViewController {
    var UINibName: String {
        get { return "SparkPlayerView" }
    }

    public override func loadView() {
        guard let resourceBundle = SparkPlayer.getResourceBundle() else {
            return super.loadView()
        }

        view = resourceBundle.loadNibNamed(UINibName, owner: self, options: nil)?.first as! SparkPlayerView
    }

    var delegate: SparkPlayerInternalDelegate!
    var timeFormatter: DateComponentsFormatter!
    var timeFont: UIFont?
    var timeHeight: CGFloat!
    private var timer: Timer?
    private var pauseIcon: UIImage!
    private var playIcon: UIImage!
    private var replayIcon: UIImage!

    var sparkView: SparkPlayerView! {
        get {
            return self.view as! SparkPlayerView
        }
    }

    var playerLayer: AVPlayerLayer? {
        didSet {
            if let layer = self.playerLayer {
                self.view.layer.insertSublayer(layer, at: 0)
                resizePlayerLayer()
            }
        }
    }

    var seeking = false

    private var closeMenuItem: MenuItem!
    private var _mainMenu: SparkPlayerMenuViewController?
    var mainMenu: SparkPlayerMenuViewController {
        if let menu = _mainMenu {
            return menu
        }

        let menu = SparkPlayerMenuViewController()
        menu.closeItem = closeMenuItem

        menu.items = [
            MenuItem(menu, iconName: "MenuQuality", text: "Quality",
                action: { self.openMenu(menu: self.qualityMenu) }),
            MenuItem(menu, iconName: "MenuSpeed", text: "Playback speed",
                disabled: { return self.delegate?.isLiveStream() ?? false },
                action: { self.openMenu(menu: self.speedMenu) }
            ),
        ]

        _mainMenu = menu
        return menu
    }
    private var _speedMenu: SparkPlayerMenuViewController?
    var speedMenu: SparkPlayerMenuViewController {
        if let menu = _speedMenu {
            return menu
        }

        let menu = SparkPlayerMenuViewController()
        menu.closeItem = closeMenuItem

        // Uncomment if need to go back instead of closing menu completely
        // menu.cancelItem = MenuItem(iconName: "MenuClose", text: "Cancel") { self.openMenu(menu: self.mainMenu) }

        let rates: [Float] = [0.25, 0.5, 0.75, 1, 1.25, 1.5, 2]

        var items: [RateMenuItem] = []
        rates.forEach { (rate) in
            items.append(RateMenuItem(menu, delegate: delegate, rate: rate, text: rate == 1 ? "Normal" : nil))
        }

        menu.items = items

        _speedMenu = menu
        return menu
    }
    private var _qualityMenu: SparkPlayerMenuViewController?
    var qualityMenu: SparkPlayerMenuViewController {
        if let menu = _qualityMenu {
            return menu
        }

        let menu = SparkPlayerMenuViewController()
        menu.closeItem = closeMenuItem

        // Uncomment if need to go back instead of closing menu completely
        // menu.cancelItem = MenuItem(iconName: "MenuClose", text: "Cancel") { self.openMenu(menu: self.mainMenu) }

        let autoInfo = HolaHLSLevelInfo()
        autoInfo.bitrate = 0
        autoInfo.url = nil
        autoInfo.resolution = "Auto"
        let autoItem = QualityMenuItem(menu, delegate: delegate,
            levelInfo: autoInfo)

        var qualityItems: [MenuItem] = []
        delegate.getQualityList().forEach { (level) in
            // XXX volodymyr: HLSParser will return bitrate=1 for single-level
            // manifest without stream info, we force 'Auto' label in this case
            guard level.resolution != nil || level.bitrate.doubleValue>1 else {
                return
            }
            qualityItems.append(QualityMenuItem(menu, delegate: delegate,
                levelInfo: level))
        }

        menu.items = qualityItems.count==1 ? qualityItems :
            [autoItem]+qualityItems
        _qualityMenu = menu
        return menu
    }
    var activeMenu: SparkPlayerMenuViewController?

    override func viewDidLoad() {
        super.viewDidLoad()

        closeMenuItem = MenuItem(nil, iconName: "MenuClose", text: "Cancel"){ self.closeMenu() }
        sparkView.setup()

        if let resourceBundle = SparkPlayer.getResourceBundle() {
            playIcon = UIImage(named: "Play", in: resourceBundle, compatibleWith: nil)
            pauseIcon = UIImage(named: "Pause", in: resourceBundle, compatibleWith: nil)
            replayIcon = UIImage(named: "Replay", in: resourceBundle, compatibleWith: nil)
        }

        timeFormatter = DateComponentsFormatter()
        timeFormatter.zeroFormattingBehavior = .pad
        timeFormatter.allowedUnits = [.minute, .second]

        var tap = UITapGestureRecognizer(target: self,
	    action: #selector(SparkPlayerController.onPlayerTap(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
        tap = UITapGestureRecognizer(target: self,
            action:#selector(SparkPlayerController.onLiveTap(_:)))
        sparkView.liveLabel.isUserInteractionEnabled = true
        sparkView.liveLabel.addGestureRecognizer(tap)
        tap = UITapGestureRecognizer(target: self,
            action:#selector(SparkPlayerController.onLiveTap(_:)))
        sparkView.liveDot.isUserInteractionEnabled = true
        sparkView.liveDot.addGestureRecognizer(tap)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        timeFont = sparkView.currentTimeLabel.font
        timeHeight = sparkView.currentTimeLabel.frame.height

        // update UI with player's data
        self.timeupdate()
        self.onPlayPause()

        activateView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func resizePlayerLayer() {
        // XXX alexeym TODO: display controls only above real video frame
        if let layer = self.playerLayer {
            layer.frame.size = self.view.frame.size
        }
    }

    override func viewDidLayoutSubviews() {
        resizePlayerLayer()
        sparkView.controlsBackground.frame.size = view.frame.size
    }

    func activateView(withSlider sliderState: ThumbStates = .Focused) {
        if let timer = self.timer {
            timer.invalidate()
        }

        setSliderState(sliderState)
        sparkView.fade(.In)

        if (!seeking) {
            self.timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(SparkPlayerController.deactivateView), userInfo: nil, repeats: false)
        }
    }

    @objc func deactivateView() {
        let isPaused = delegate.isPaused()

        if (isPaused) {
            setSliderState(.Focused)
            sparkView.fade(.In)
        } else {
            setSliderState(.Normal)
            sparkView.fade(.Out)
        }
    }

    func sec2time(_ value: Float) -> CMTime {
        return CMTimeMakeWithSeconds(Float64(value), Int32(NSEC_PER_SEC))
    }
    
    func sec2end() -> Float {
        guard !seeking else {
            return sparkView.positionSlider.maximumValue -
                sparkView.positionSlider.value
        }
        guard let range = getSeekableRange() else { return 0 }
        let end = range.end.seconds
        let pos = delegate.currentTime().seconds
        return Float(max(end-pos, 0))
    }
    
    func getSeekableRange() -> CMTimeRange? {
        let ranges = delegate.seekableTimeRanges()
        guard ranges.count>0 else { return nil }
        return ranges[0]
    }
    
    func setSliderState(_ state: ThumbStates) {
        sparkView.positionSlider.setThumbState(state)
    }
    
    func returnToLive() {
        guard sparkView.getVideoMode() == .DVR else { return }
        sparkView.positionSlider.value = sparkView.positionSlider.maximumValue
        sparkView.setVideoMode(.DVR_LIVE)
        updateTimeLabels()
        delegate.seekTo(sec2time(sparkView.positionSlider.value))
    }
    
    func adjustPosition(){
        updateVideoMode()
        guard sparkView.getVideoMode() == .DVR else { return }
        updatePositionSlider()
        updateTimeLabels()
        let min = sparkView.positionSlider.minimumValue
        if (delegate.currentTime().seconds < Double(min)) {
            delegate.seekTo(sec2time(min))
        }
    }

    func onSeekStart() {
        seeking = true
        activateView(withSlider: .Highlighted)
        delegate.seekStart(sec2time(sparkView.positionSlider.value));
    }

    func onSeekMove() {
        updateVideoMode()
        updateTimeLabels()
        delegate.seekMove(sec2time(sparkView.positionSlider.value));
    }

    func onSeekEnd() {
        updateVideoMode()
        updateTimeLabels()
        seeking = false
        activateView(withSlider: .Focused)
        if (sparkView.getVideoMode() == .DVR_LIVE) {
            sparkView.positionSlider.value =
                sparkView.positionSlider.maximumValue
        }
        delegate.seekTo(sec2time(sparkView.positionSlider.value))
    }
    
    func updateVideoMode() {
        let mode: VideoMode = !delegate.isLiveStream() ? .VOD :
            !delegate.isDvrEnabled() ? .LIVE : sec2end()<20 ? .DVR_LIVE :
            sec2end()>40 ? .DVR : sparkView.getVideoMode()
        sparkView.setVideoMode(mode)
    }
    
    func updateTimeLabels() {
        guard let font = timeFont else { return }
        let pos = delegate.currentTime()
        let dur = delegate.duration()
        if (delegate.isLiveStream()) {
            let timeBehind = sec2time(seeking ||
                sparkView.getVideoMode() == .DVR ? -sec2end() : 0)
            let timeBehindString = formatTime(timeBehind,
                forDuration: timeBehind)
            sparkView.durationLabel.text = timeBehindString
            sparkView.durationWidth.constant =
                timeBehindString.width(withFont: font)
        }
        else if (dur.seconds>0) {
            let currentTimeString = formatTime(pos, forDuration: dur)
            sparkView.currentTimeLabel.text = currentTimeString
            sparkView.currentTimeWidth.constant =
                currentTimeString.width(withFont: font)
            let durationString = formatTime(dur, forDuration: dur)
            sparkView.durationLabel.text = durationString
            sparkView.durationWidth.constant =
                durationString.width(withFont: font)
        }
    }
    
    func updatePositionSlider() {
        let pos = delegate.currentTime()
        let dur = delegate.duration()
        let range = getSeekableRange()
        if (delegate.isLiveStream() && range != nil) {
            sparkView.positionSlider.minimumValue =
                Float(range!.start.seconds)
            sparkView.positionSlider.maximumValue =
                Float(range!.end.seconds)
            sparkView.positionSlider.value = sparkView.getVideoMode() == .DVR ?
                max(sparkView.positionSlider.minimumValue, Float(pos.seconds)) :
                min(sparkView.positionSlider.maximumValue, Float(pos.seconds))
        }
        else if (dur.seconds>0) {
            sparkView.positionSlider.minimumValue = 0
            sparkView.positionSlider.maximumValue = Float(dur.seconds)
            sparkView.positionSlider.value = Float(pos.seconds)
        }
        sparkView.positionSlider.loaded = delegate.loadedTimeRanges()
    }
    
    func formatTime(_ time: CMTime, forDuration duration: CMTime) -> String {
        let seconds = time.seconds
        if (!time.isValid || time.isIndefinite || seconds == 0) {
            return "0:00"
        }

        let needHours = duration.seconds >= 3600
        if (needHours) {
            timeFormatter.allowedUnits = [.hour, .minute, .second]
        } else {
            timeFormatter.allowedUnits = [.minute, .second]
        }
        return timeFormatter.string(from: TimeInterval(time.seconds))!
    }

    func openMenu(menu: SparkPlayerMenuViewController) {
        closeMenu() {
            DispatchQueue.main.async {
                self.present(menu, animated: true) {
                    self.activeMenu = menu
                }
            }
        }
    }

    func closeMenu(completion: (() -> Void)? = nil) {
        if let menu = self.activeMenu {
            self.activeMenu = nil
            DispatchQueue.main.async {
                menu.dismiss(animated: true, completion: completion)
            }
        } else if let cb = completion {
            cb()
        }
    }

    func setRate(_ rate: Float) {
        self.delegate.setRate(rate)
        self.closeMenu()
    }
}

// Handling Player events
extension SparkPlayerController {
    func timeupdate() {
        guard !seeking && !delegate.isSeeking() else { return }
        updateVideoMode()
        updatePositionSlider()
        updateTimeLabels()
    }

    func onPlayPause() {
        let isPaused = delegate.isPaused()
        let isReplay = delegate.isEnded()
        sparkView.playButton.setImage(isReplay ? replayIcon : isPaused ? playIcon : pauseIcon, for: .normal)
        if (!isPaused) {
            adjustPosition()
        }
    }
}

// Controls handling
extension SparkPlayerController {
    @objc func onPlayerTap(_ gestureRecognizer: UITapGestureRecognizer) {
        activateView()
    }
    
    @objc func onLiveTap(_ gestureRecognizer: UITapGestureRecognizer) {
        activateView()
        returnToLive()
    }

    @IBAction func onPlayButton(sender: UIButton!) {
        if let delegate = self.delegate {
            delegate.onPlayClick()
        }
    }

    @IBAction func onFsButton(sender: UIButton!) {
        if let delegate = self.delegate {
            delegate.onFullscreenClick()
        }
    }

    @IBAction func onSliderDown(sender: UISlider!) {
        onSeekStart()
    }

    @IBAction func onSliderDrag(sender: UISlider!) {
        onSeekMove();
    }

    @IBAction func onSliderUp(sender: UISlider!) {
        onSeekEnd()
    }

    @IBAction func onMenuButton(sender: UIButton!) {
        openMenu(menu: mainMenu)
    }
    
}
