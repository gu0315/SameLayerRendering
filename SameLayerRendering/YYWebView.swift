//
//  YYWebView.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/8/28.
//

import UIKit
import WebKit
import Foundation
class YYWebView: WKWebView {
    
    private var didHandleWKContentGestrues = false
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if !didHandleWKContentGestrues {
            handleWKContentGestures()
            didHandleWKContentGestrues = true
        }
        let cls: AnyClass = NSClassFromString("WKChildScrollView")!
        if let childScrollView = hitView, childScrollView.isKind(of: cls) {
            var hitView: UIView?
            for subview in childScrollView.subviews.reversed() {
                let point = subview.convert(point, from: self)
                if let hit = subview.hitTest(point, with: event) {
                    hitView = hit
                    break
                }
            }
            if hitView != nil {
                return hitView
            }
        }
        return hitView
    }
    
    
    // 拦截手势
    func handleWKContentGestures() {
        let cls: AnyClass = NSClassFromString("WKScrollView")!
        if scrollView.isKind(of: cls) {
            let cls: AnyClass = NSClassFromString("WKContentView")!
            scrollView.subviews.first { subview -> Bool in
                return subview.isKind(of: cls)
            }?.gestureRecognizers?.forEach { gesture in
                let cls: AnyClass = NSClassFromString("UITextTapRecognizer")!
                // fix: 原生输入框聚焦时, 再次点击会失焦
                if gesture.isKind(of: cls) {
                    gesture.isEnabled = false
                }
                gesture.cancelsTouchesInView = false
                gesture.delaysTouchesBegan = false
                gesture.delaysTouchesEnded = false
            }
        }
    }
}

extension WKWebView {
    
    func findWKChildScrollViewById(_ id: String, rootView: UIView) -> UIView? {
        let cls: AnyClass = NSClassFromString("WKCompositingView")!
        if rootView.isKind(of: cls) && rootView.description.contains(id) {
            let cls: AnyClass = NSClassFromString("WKChildScrollView")!
            guard let childScrollView = rootView.subviews.first, childScrollView.isKind(of: cls) else {
                return nil
            }
            for ges in childScrollView.gestureRecognizers ?? [] {
                childScrollView.removeGestureRecognizer(ges)
            }
            return childScrollView
        }
        for subview in rootView.subviews {
            if let hit = findWKChildScrollViewById(id, rootView: subview)  {
                return hit
            }
        }
        return nil
    }
    
}
