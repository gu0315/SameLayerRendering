//
//  XVideoElement.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/30.
//

import UIKit
import ZFPlayer


class XVideoElement: XSLBaseElement {
    
    var src = ""
    
    static var ZFAVPlayerManagerKey = "ZFAVPlayerManagerKey"
    
    static var ZFPlayerControllerKey = "ZFPlayerControllerKey"
    
    private lazy var manager: ZFAVPlayerManager = {
        guard let manager: ZFAVPlayerManager = objc_getAssociatedObject(webView!, &XVideoElement.ZFAVPlayerManagerKey) as? ZFAVPlayerManager else {
            let m = ZFAVPlayerManager()
            objc_setAssociatedObject(webView!, &XVideoElement.ZFAVPlayerManagerKey, m, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return m
        }
        return manager
    }()
    
    lazy var playBtn: UIButton = {
        let btn = UIButton.init(frame: .init(x: 0, y: 0, width: 100, height: 50))
        btn.backgroundColor = .red
        btn.setTitle("play", for: .normal)
        btn.addTarget(self, action: #selector(play), for: .touchUpInside)
        return btn
    }()
    
    @objc func play() {
        player.containerView = containerView
        player.controlView = controlView
        manager.stop()
        if let videoURL = URL(string: self.src) {
            player.assetURL = videoURL
        }
    }
    
    private lazy var player: ZFPlayerController = {
        guard let zPlayer: ZFPlayerController = objc_getAssociatedObject(webView!, &XVideoElement.ZFPlayerControllerKey) as? ZFPlayerController else {
            let player: ZFPlayerController = ZFPlayerController.init(scrollView: webView!.scrollView, playerManager: manager, containerView: containerView)
            player.controlView = controlView
            player.shouldAutoPlay = false
            player.isWWANAutoPlay = false
            player.playerDisapperaPercent = 1.0
            objc_setAssociatedObject(webView!, &XVideoElement.ZFPlayerControllerKey, player, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return player
        }
        return zPlayer
    }()
    
    private lazy var controlView = ZFPlayerControlView()
    
    override init() {
        super.init()
        
        self.containerView.addSubview(playBtn)
        self.containerView.viewDidRemoveWindow = {
            self.manager.stop()
            self.manager.assetURL = nil
        }
    }
    
    @objc override func elementConnected() {
        super.elementConnected()
    }
    
    @objc override func elementRendered() {
        super.elementRendered()
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
        controlView.layoutIfNeeded()
        controlView.setNeedsDisplay()
    }
    
    @objc override func setStyleString(_ style: String) {
        super.setStyleString(style)
    }
    
    @objc override func setXSLStyleString(_ style: String) {
        super.setXSLStyleString(style)
    }
    
    @objc func xsl__src(_ args: Dictionary<String, Any>) {
        guard let urlString = args["newValue"] as? String else { return }
        if (self.src == urlString) { return }
        self.src = urlString
        if let videoURL = URL(string: self.src) {
            player.assetURL = videoURL
        }
    }
}

