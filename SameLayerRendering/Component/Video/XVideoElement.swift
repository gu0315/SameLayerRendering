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
    
    let manager = ZFAVPlayerManager()
    
    private lazy var player: ZFPlayerController = {
        let player = ZFPlayerController.init(playerManager: manager, containerView: containerView)
        player.controlView = controlView
        player.shouldAutoPlay = false
        player.playerDisapperaPercent = 1.0
        return player
    }()
    
    private lazy var controlView = ZFPlayerControlView()
    
    override init() {
        super.init()
    }
    
    @objc override func elementConnected() {
        super.elementConnected()
    }
    
    @objc override func elementRendered() {
        super.elementRendered()
    }

    @objc override class func elementName() -> String {
        return "hybrid-video"
    }
    
    override class func isElementValid() -> Bool {
        return true
    }
    
    @objc override func setSize(_ size: CGSize) {
        super.setSize(size)
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
