//
//  FullScreenAnimated.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/10.
//

import UIKit
import SnapKit
class FullScreenAnimated: NSObject, UIViewControllerAnimatedTransitioning {
    
    weak var playerView: AVPlayerView?
    
    private var originSize: CGSize = .zero
    
    init(_playerView: AVPlayerView) {
        playerView  =  _playerView
        originSize = _playerView.frame.size
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.25
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let playerView = playerView else {
            return
        }
        guard let toView  = transitionContext.view(forKey: .to) else {
            return
        }
        transitionContext.containerView.addSubview(toView)
        toView.addSubview(playerView)
        playerView.snp.remakeConstraints { make in
            make.width.equalTo(UIScreen.main.bounds.height)
            make.height.equalTo(UIScreen.main.bounds.width)
            make.center.equalTo(toView)
        }
        playerView.playerLayer?.videoGravity = .resizeAspectFill
        playerView.transform = .init(rotationAngle: .pi / 2)
        playerView.setNeedsLayout()
        playerView.layoutSubviews()
        transitionContext.containerView.setNeedsLayout()
        transitionContext.containerView.layoutIfNeeded()
        toView.snp.updateConstraints { make in
           make.center.equalTo(transitionContext.containerView.center)
           make.size.equalTo(transitionContext.containerView.bounds.size)
        }
        transitionContext.completeTransition(true)
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        
    }
}
