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
    
    var configuration: [String: Any]  = [:]
    
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
            controlView.showTitle("测试", coverURLString: "https://upload-images.jianshu.io/upload_images/635942-14593722fe3f0695.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240", fullScreenMode: .portrait)
        }
    }
    
    private lazy var player: ZFPlayerController = {
        guard let zPlayer: ZFPlayerController = objc_getAssociatedObject(webView!, &XVideoElement.ZFPlayerControllerKey) as? ZFPlayerController else {
            let player: ZFPlayerController = ZFPlayerController.init(playerManager: manager, containerView: containerView)
            player.controlView = controlView
            player.shouldAutoPlay = false
            player.playerDisapperaPercent = 1.0
            objc_setAssociatedObject(webView!, &XVideoElement.ZFPlayerControllerKey, player, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return player
        }
        return zPlayer
    }()
    
    private lazy var controlView = ZFPlayerControlView()
    
    required init() {
        super.init()
        self.containerView.addSubview(playBtn)
        self.containerView.viewDidRemoveWindow = {
            self.manager.stop()
            self.manager.assetURL = nil
        }
    }
    
    @objc override func elementConnected(_ params: [String: Any]) {
        super.elementConnected(params)
        configuration = params
        let autoplay = params["autoplay"] as? Bool
        print(params)
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
    
            self.controlView.showTitle("测试", coverURLString: "https://upload-images.jianshu.io/upload_images/635942-14593722fe3f0695.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240", fullScreenMode: .portrait)
        }
    }
}

