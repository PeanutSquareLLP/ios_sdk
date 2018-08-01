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
            MenuItem(menu, iconName: "MenuQuality", text: "Quality") { self.openMenu(menu: self.qualityMenu) },
            MenuItem(menu, iconName: "MenuSpeed", text: "Playback speed") { self.openMenu(menu: self.speedMenu) },
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
        var items: [MenuItem] = [
            QualityMenuItem(menu, delegate: delegate, levelInfo: autoInfo)
        ]

        let qualityList = delegate.getQualityList()
        qualityList.forEach { (level) in
            let item = QualityMenuItem(menu, delegate: delegate, levelInfo: level)
            items.append(item)
        }

        menu.items = items

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

        let tap = UITapGestureRecognizer(target: self, action: #selector(SparkPlayerController.onPlayerTap(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tap)
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

    func setSliderState(_ state: ThumbStates) {
        sparkView.positionSlider.setThumbState(state)
    }

    func onSeekStart() {
        seeking = true
        activateView(withSlider: .Highlighted)

        let time = CMTimeMakeWithSeconds(Float64(sparkView.positionSlider.value), Int32(NSEC_PER_SEC))
        delegate.seekStart(time);
    }

    func onSeekMove() {
        let time = CMTimeMakeWithSeconds(Float64(sparkView.positionSlider.value), Int32(NSEC_PER_SEC))
        delegate.seekMove(time);
    }

    func onSeekEnd() {
        seeking = false
        activateView(withSlider: .Focused)

        let time = CMTimeMakeWithSeconds(Float64(sparkView.positionSlider.value), Int32(NSEC_PER_SEC))
        delegate.seekTo(time)
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
        guard let font = timeFont else { return }
        let isLive = delegate.isLiveStream()
        sparkView.setLive(isLive)

        let currentTime = delegate.currentTime()
        let duration = isLive ? currentTime : delegate.duration()

        let currentTimeString = formatTime(currentTime, forDuration: duration)
        sparkView.currentTimeLabel.text = currentTimeString
        sparkView.currentTimeWidth.constant =
            currentTimeString.width(withFont: font)

        if (!isLive) {
            if (!seeking && !delegate.isSeeking()) {
                sparkView.positionSlider.maximumValue = Float(duration.seconds)
                sparkView.positionSlider.value = Float(currentTime.seconds)
            }
            sparkView.positionSlider.loaded = delegate.loadedTimeRanges()

            let durationString = formatTime(duration, forDuration: duration)
            sparkView.durationLabel.text = durationString
            sparkView.durationWidth.constant =
                durationString.width(withFont: font)
        }
    }

    func onPlayPause() {
        let isPaused = delegate.isPaused()
        let isReplay = delegate.isEnded()
        sparkView.playButton.setImage(isReplay ? replayIcon : isPaused ? playIcon : pauseIcon, for: .normal)
    }
}

// Controls handling
extension SparkPlayerController {
    @objc func onPlayerTap(_ gestureRecognizer: UITapGestureRecognizer) {
        activateView()
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
