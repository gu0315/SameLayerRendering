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
    
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
    
    func isScrollViewFoundById(_ id: String, rootView: UIView) -> UIView? {
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
            if let hit = isScrollViewFoundById(id, rootView: subview)  {
                return hit
            }
        }
        return nil
    }
}


extension UIScrollView {
    // TODO 待优化，会影响全局
    // https://patent-image.qichacha.com/pdf/7a81ca75aa22d5688a8d0c152e905b03.pdf
    override open func didMoveToWindow() {
        super.didMoveToWindow()
        // ⚠️，此处要异步 🐷异步闭包在当前runloop完成之后排队等待运行🐷
        DispatchQueue.main.async {
            let cls: AnyClass = NSClassFromString("WKChildScrollView")!
            if self.isKind(of: cls) {
                // 从父视图的layer(层)的name(名称)中解析containerID(容器标识) eg: applets-container-id
                if let id = self.superview?.description, id.contains("applets-id") {
                    // 同层渲染场景
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "WKChildScrollView-DidMoveToWindow"), object: self, userInfo: ["id": id])
                } else {

                }
            }
        }
    }
}




