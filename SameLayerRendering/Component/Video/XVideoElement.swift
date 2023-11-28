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
    
    var currentTime: TimeInterval = 0
    
    static var ZFAVPlayerManagerKey = "ZFAVPlayerManagerKey"
    
    static var ZFPlayerControllerKey = "ZFPlayerControllerKey"
    
    lazy var coverImg: UIImageView = {
        let img = UIImageView.init()
        img.isUserInteractionEnabled = true
        return img
    }()
    
    lazy var playBtn: UIButton = {
        let btn = UIButton.init(frame: .init(x: 0, y: 0, width: 100, height: 50))
        btn.setImage(UIImage.init(named: "new_allPause_44x44_"), for: .selected)
        btn.setImage(UIImage.init(named: "new_allPlay_44x44_"), for: .normal)
        btn.addTarget(self, action: #selector(playVideo), for: .touchUpInside)
        return btn
    }()
    
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
    
    private lazy var player: ZFPlayerController = {
        withUnsafePointer(to: &XVideoElement.ZFPlayerControllerKey) { pointer in
            guard let zPlayer: ZFPlayerController = objc_getAssociatedObject(webView!, pointer) as? ZFPlayerController else {
                let player: ZFPlayerController = ZFPlayerController.init(playerManager: manager, containerView: containerView)
                player.controlView = ZFPlayerControlView()
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
    
    
    required init() {
        super.init()
        self.containerView.addSubview(coverImg)
        self.coverImg.addSubview(playBtn)
        self.containerView.viewDidRemoveWindow = { [weak self]  in
            guard let self = self else { return }
            self.player.stop()
            self.player.assetURL = nil
        }
    }
    
    @objc func playVideo() {
        playBtn.isSelected = !playBtn.isSelected
        //视频视图的父视图
        player.containerView = containerView
        if (playBtn.isSelected) {
            let xslElementMap = webView?.xslElementMap
            if let values = xslElementMap?.values {
                for el in values {
                    if (el.isKind(of: XVideoElement.self)) {
                        guard let obj: XVideoElement = el as? XVideoElement else {
                            continue
                        }
                        if (obj.playBtn.isSelected && obj.currentTime > 0) {
                            /*DispatchQueue.main.async {
                                obj.thumbnailImageAtCurrentTime(cTime: obj.currentTime, url: .init(string: obj.src)) { img in
                                    if img != nil  {
                                        obj.coverImg.image = img
                                    }
                                }
                            }*/
                            obj.player.currentPlayerManager.pause()
                        }
                        obj.playBtn.isSelected = false
                    }
                }
            }
            if let videoURL = URL(string: self.src) {
                if let proxyURL = KTVHTTPCache.proxyURL(withOriginalURL: videoURL) {
                    player.assetURL = proxyURL
                } else {
                    player.assetURL = videoURL
                }
                if (currentTime > 0) {
                    player.currentPlayerManager.seek(toTime: currentTime)
                }
                player.currentPlayerManager.play()
                player.playerPlayTimeChanged = { [weak self] _asset, _currentTime,  _duration in
                    guard let self = self else { return }
                    if (_currentTime > 0) {
                        self.currentTime = _currentTime
                    }
                }
            }
        } else {
            player.currentPlayerManager.pause()
        }
    }
    
    func thumbnailImageAtCurrentTime(cTime: TimeInterval, url: URL?, handler: @escaping (UIImage?) -> Void) {
        if let url = url {
            let asset = AVAsset(url: url)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: cTime, preferredTimescale: 1)
            var actualTime: CMTime = CMTime.zero
            do {
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: &actualTime)
                let thumbnail = UIImage(cgImage: cgImage)
                handler(thumbnail)
            } catch _ as NSError {
                handler(nil)
            }
        } else {
            handler(nil)
        }
    }
    
    @objc override func elementConnected(_ params: [String: Any]) {
        super.elementConnected(params)
        configuration = params
        let autoplay = params["autoplay"] as? Bool
        player.shouldAutoPlay = autoplay ?? false
        if let poster = params["poster"] as? String {
            coverImg.sd_setImage(with: URL(string: poster))
        }
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
        coverImg.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        playBtn.center = containerView.center
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


