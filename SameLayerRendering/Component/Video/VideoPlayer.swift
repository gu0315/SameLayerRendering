//
//  VideoPlayer.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/9.
//
import UIKit
import AVFoundation
import AVKit
import SnapKit

class AVPlayerView: ContainerHookView {
    // AVPlayer 相关属性
    var player: AVPlayer?
    
    var playerLayer: AVPlayerLayer?
    
    private var animationTransitioning: FullScreenAnimated?
    
    private var fullScreenViewController: FullScreenViewController?
    
    var isFullScreen = false
    
    var videoUrl = ""
    
    private var originFream: CGRect = .zero
    
    // 控件元素
    private var playButton: UIButton!
    
    private var fullScreenButton: UIButton!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        originFream = frame
        // 初始化 AVPlayer
        player = AVPlayer()
        playerLayer = AVPlayerLayer(player: player)
        self.layer.addSublayer(playerLayer!)
        
        
        // 创建播放按钮
        playButton = UIButton(type: .system)
        playButton.setTitle("Play", for: .normal)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
        
        // 添加控件到视图
        self.addSubview(playButton)
        playButton.snp.makeConstraints { make in
            make.center.equalTo(self)
            make.width.height.equalTo(100)
        }
        
        fullScreenButton = UIButton(type: .system)
        fullScreenButton.setTitle("全屏", for: .normal)
        fullScreenButton.addTarget(self, action: #selector(fullScreenButtonTapped), for: .touchUpInside)
        self.addSubview(fullScreenButton)
        fullScreenButton.snp.makeConstraints { make in
            make.bottom.equalTo(self).offset(-20)
            make.right.equalTo(self).offset(-20)
            make.width.height.equalTo(100)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = self.bounds
    }
    
    @objc func orientationDidChange() {
        let orientation = UIDevice.current.orientation
        //
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("播放器--------deinit")
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
            guard let rootViewController = UIApplication.shared.keyWindow?.rootViewController else { return }
            animationTransitioning = FullScreenAnimated.init(_playerView: self)
            fullScreenViewController = FullScreenViewController()
            fullScreenViewController?.transitioningDelegate = self
            fullScreenViewController?.modalPresentationStyle = .fullScreen
            rootViewController.present(fullScreenViewController!, animated: true, completion: {
                 UIViewController.attemptRotationToDeviceOrientation()
            })
        } else {
            
            self.setNeedsLayout()
            self.layoutSubviews()
            animationTransitioning?.playerView!.snp.updateConstraints { make in
                make.center.equalToSuperview()
                make.width.equalTo(originFream.width)
                make.height.equalTo(originFream.height)
            }
            self.transform = .init(rotationAngle: 0)
            fullScreenViewController?.dismiss(animated: false)
            fullScreenViewController = nil
        }
    }
    
    func play() {
        player?.play()
        playButton.setTitle("Pause", for: .normal)
    }
    
    // 设置视频URL并准备播放
    func setVideoURL(_ url: String) {
        videoUrl = url
        guard let url = URL.init(string: url) else {
            return
        }
        let playerItem = AVPlayerItem(url: url)
        player?.replaceCurrentItem(with: nil)
        player?.replaceCurrentItem(with: playerItem)
        player?.play()
        playButton.setTitle("Pause", for: .normal)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
               
    }
    
    @objc func playerDidFinishPlaying() {
           player?.seek(to: .zero)
           player?.play()
       }
    
    func destroy() {
        player?.replaceCurrentItem(with: nil)
    }
}


extension AVPlayerView: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animationTransitioning
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return animationTransitioning
    }
}
