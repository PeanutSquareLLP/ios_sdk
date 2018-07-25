//
//  SparkPlayerMenuItem.swift
//  SparkPlayer
//
//  Created by norlin on 13/03/2018.
//

import UIKit

class MenuItem {
    var iconName: String?
    var text: String
    var action: (() -> Void)?

    weak var menu: SparkPlayerMenuViewController?

    var icon: UIImage? {
        if let name = self.iconName {
            return UIImage(named: name, in: SparkPlayer.getResourceBundle(), compatibleWith: nil)
        }

        return nil
    }

    init(_ menu: SparkPlayerMenuViewController?, iconName: String?, text: String, action: (() -> Void)?) {
        self.menu = menu
        self.iconName = iconName
        self.text = text
        self.action = action
    }
}

class SelectableMenuItem: MenuItem {
    private var _iconName: String? = "MenuCheck"
    override var iconName: String? {
        get {
            let active = self.check()
            return active ? _iconName : nil
        }
        set {
            _iconName = newValue
        }
    }

    private var _active = false
    fileprivate func check() -> Bool {
        _active = !_active
        return _active
    }
}

class QualityMenuItem: SelectableMenuItem {
    var levelInfo: HolaHLSLevelInfo
    var delegate: SparkPlayerInternalDelegate

    init(_ menu: SparkPlayerMenuViewController, delegate: SparkPlayerInternalDelegate, levelInfo: HolaHLSLevelInfo) {
        self.delegate = delegate
        self.levelInfo = levelInfo

        let text: String
        if let resolution = levelInfo.resolution {
            text = resolution
        } else {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
            formatter.countStyle = .file
            let bitrate = formatter.string(fromByteCount: levelInfo.bitrate as! Int64)
            text = "\(bitrate)ps"
        }

        super.init(menu, iconName: "MenuCheck", text: text, action: nil)

        unowned let weakSelf = self
        self.action = {
            if (!self.check()) {
                try? weakSelf.delegate.setQuality(withURL: weakSelf.levelInfo.url)
            }
            if let menu = self.menu {
                menu.performClose(menu.closeItem)
            }
        }
    }

    override fileprivate func check() -> Bool {
        let _itemURL = levelInfo.url == nil ? delegate.getURL() : levelInfo.url

        guard
            let itemURL = _itemURL,
            let url = delegate.getCurrentURL()
        else {
            return false
        }

        let result = itemURL == url
        return result
    }
}

class RateMenuItem: SelectableMenuItem {
    var delegate: SparkPlayerInternalDelegate
    var rate: Float

    init(_ menu: SparkPlayerMenuViewController, delegate: SparkPlayerInternalDelegate, rate: Float, text: String? = nil) {
        self.delegate = delegate
        self.rate = rate

        super.init(menu, iconName: "MenuCheck", text: text ?? "\(rate)", action: nil)

        unowned let weakSelf = self
        self.action = {
            weakSelf.delegate.setRate(rate)
            if let menu = self.menu {
                menu.performClose(menu.closeItem)
            }
        }
    }

    override fileprivate func check() -> Bool {
       return delegate.getRate() == rate
    }
}
