//
//  XVideoElement.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/30.
//

import UIKit
import ZFPlayer
import WebKit
import KTVHTTPCache

class XVideoElement: XSLBaseElement {
    
    var src = ""
    
    var configuration: [String: Any]  = [:]
    
    static var ZFAVPlayerManagerKey = "ZFAVPlayerManagerKey"
    
    static var ZFPlayerControllerKey = "ZFPlayerControllerKey"
    
    private lazy var manager: ZFAVPlayerManager = {
        withUnsafePointer(to: &XVideoElement.ZFAVPlayerManagerKey) { pointer in
            guard let manager: ZFAVPlayerManager = objc_getAssociatedObject(webView!, pointer) as? ZFAVPlayerManager else {
                let m = ZFAVPlayerManager()
                objc_setAssociatedObject(webView!, pointer, m, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return m
            }
            return manager
        }
    }()
    
    lazy var coverImg: UIImageView = {
        let img = UIImageView.init()
        return img
    }()
    
    lazy var playBtn: UIButton = {
        let btn = UIButton.init(frame: .init(x: 0, y: 0, width: 100, height: 50))
        btn.setImage(UIImage.init(named: "new_allPause_44x44_"), for: .normal)
        btn.setImage(UIImage.init(named: "new_allPlay_44x44_"), for: .normal)
        btn.addTarget(self, action: #selector(play(_ :)), for: .touchUpInside)
        return btn
    }()
    
    @objc func play(_ btn: UIButton) {
        player.containerView = containerView
        player.controlView = controlView
        btn.isSelected = !btn.isSelected
        if (btn.isSelected) {
            if let videoURL = URL(string: self.src) {
                if let proxyURL = KTVHTTPCache.proxyURL(withOriginalURL: videoURL) {
                    player.assetURL = proxyURL
                } else {
                    player.assetURL = videoURL
                }
                manager.play()
            }
        } else {
            manager.pause()
        }
    }
    
    private lazy var player: ZFPlayerController = {
        withUnsafePointer(to: &XVideoElement.ZFPlayerControllerKey) { pointer in
            guard let zPlayer: ZFPlayerController = objc_getAssociatedObject(webView!, pointer) as? ZFPlayerController else {
                let player: ZFPlayerController = ZFPlayerController.init(playerManager: manager, containerView: containerView)
                player.controlView = controlView
                player.shouldAutoPlay = false
                player.playerDisapperaPercent = 1.0
                player.disableGestureTypes = .pan
                player.orientationWillChange = { _, isFullScreen in
                    if let appdelegate = UIApplication.shared.delegate as? AppDelegate {
                        appdelegate.isAllowOrientationRotation = isFullScreen
                    }
                }
                objc_setAssociatedObject(webView!, pointer, player, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return player
            }
            return zPlayer
        }
    }()
    
    private lazy var controlView = ZFPlayerControlView()
    
    required init() {
        super.init()
        self.containerView.addSubview(coverImg)
        self.coverImg.addSubview(playBtn)
        self.containerView.viewDidRemoveWindow = { [weak self]  in
            guard let self = self else { return }
            self.manager.stop()
            self.manager.assetURL = nil
        }
    }
    
    @objc override func elementConnected(_ params: [String: Any]) {
        super.elementConnected(params)
        configuration = params
        let autoplay = params["autoplay"] as? Bool
        player.shouldAutoPlay = autoplay ?? false
    }
    
    @objc override func removeFromSuperView() {
        super.removeFromSuperView()
    }

    @objc override class func elementName() -> String {
        return "hybrid-video"
    }
    
    override class func isElementValid() -> Bool {
        return true
    }
    
    @objc override func setSize(_ size: CGSize) {
        super.setSize(size)
        playBtn.center = containerView.center
        coverImg.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        controlView.layoutIfNeeded()
        controlView.setNeedsDisplay()
    }
    
    @objc override func setStyleString(_ style: String) {
        super.setStyleString(style)
    }
    
    @objc func xsl__src(_ args: Dictionary<String, Any>) {
        guard let urlString = args["newValue"] as? String else { return }
        if (self.src == urlString) { return }
        self.src = urlString
        DispatchQueue.main.async {
            if !KTVHTTPCache.proxyIsRunning() {
                do {
                    try KTVHTTPCache.proxyStart()
                } catch {
                    print("KTVHTTPCache Start failed: \(error)")
                }
            }
        }
    }
    
    deinit {
        print("XVideoElement销毁")
    }
}


