//
//  VideoPlayer.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/9.
//
import UIKit
import AVFoundation
import AVKit

class AVPlayerView: ContainerHookView {
    // AVPlayer 相关属性
    private var player: AVPlayer?
    
    private var playerLayer: AVPlayerLayer?
    
    var isFullScreen = false
    
    // 控件元素
    private var playButton: UIButton!
    private var fullScreenButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        // 初始化 AVPlayer
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = self.bounds;
        layer.addSublayer(playerLayer!)
        
        // 创建播放按钮
        playButton = UIButton(type: .system)
        playButton.setTitle("Play", for: .normal)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        
        // 添加控件到视图
        addSubview(playButton)
        playButton.frame = CGRect.init(x: (self.bounds.width - 100) / 2, y: (self.bounds.height - 100) / 2, width: 100, height: 100)
        
        fullScreenButton = UIButton(type: .system)
        fullScreenButton.setTitle("全屏", for: .normal)
        fullScreenButton.addTarget(self, action: #selector(fullScreenButtonTapped), for: .touchUpInside)
        fullScreenButton.frame = CGRect.init(x: (self.bounds.width - 100), y: (self.bounds.height - 100), width: 100, height: 100)
        addSubview(fullScreenButton)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 播放按钮点击事件
    @objc private func playButtonTapped() {
        if player?.rate == 0 {
            player?.play()
            playButton.setTitle("Pause", for: .normal)
        } else {
            player?.pause()
            playButton.setTitle("Play", for: .normal)
        }
    }
    
    @objc private func fullScreenButtonTapped() {
        isFullScreen = !isFullScreen
        if (isFullScreen) {
            
        } else {
            
        }
    }
    
    // 设置视频URL并准备播放
    func setVideoURL(_ url: String) {
        guard let url = URL.init(string: url) else {
            return
        }
        let playerItem = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: playerItem)
        player?.play()
        playButton.setTitle("Pause", for: .normal)
    }
    
}



extension NSObject {
    // 获取最顶层的控制器
    @objc static func applicationTopVC() -> UIViewController? {
        var window: UIWindow? = UIApplication.shared.windows[0]
        if window?.windowLevel != UIWindow.Level.normal {
            let windows = UIApplication.shared.windows
            for tmpWin: UIWindow in windows {
                if tmpWin.windowLevel == UIWindow.Level.normal {
                    window = tmpWin
                    break
                }
            }
        }
        return self.topViewControllerWithRootViewController(rootViewController: window?.rootViewController)
    }
    
    static func topViewControllerWithRootViewController(rootViewController: UIViewController?) -> UIViewController? {
        if rootViewController == nil {
            print("❌❌❌❌❌❌无根控制器❌❌❌❌❌❌")
            return nil
        }
        if let vc = rootViewController as? UITabBarController {
            if vc.viewControllers != nil {
                return topViewControllerWithRootViewController(rootViewController: vc.selectedViewController)
            } else {
                return vc
            }
        } else if let vc = rootViewController as? UINavigationController {
            if vc.viewControllers.count > 0 {
                return topViewControllerWithRootViewController(rootViewController: vc.visibleViewController)
            } else {
                return vc
            }
        } else if let vc = rootViewController as? UISplitViewController {
            if vc.viewControllers.count > 0 {
                return topViewControllerWithRootViewController(rootViewController: vc.viewControllers.last)
            } else {
                return vc
            }
        } else if let vc = rootViewController?.presentedViewController {
            return topViewControllerWithRootViewController(rootViewController: vc)
        } else {
            return rootViewController
        }
    }
}
