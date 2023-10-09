//
//  YYWebView.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/8/28.
//

import UIKit
import WebKit
import Foundation
class WebView: WKWebView {
    
    private var didHandleWKContentGestrues = false
    
    public var tongcengContainers: Dictionary<String, UIView> = [:]
    
    public weak var sameLayerDelegate: SameLayerDelegate?
    
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
        let cls1: AnyClass = NSClassFromString("WKScrollView")!
        if self.scrollView.isKind(of: cls1) {
            let cls2: AnyClass = NSClassFromString("WKContentView")!
            guard let subview = self.scrollView.subviews.first, subview.isKind(of: cls2) else {
                return
            }
            for gesture in subview.gestureRecognizers ?? [] {
                let cls3: AnyClass = NSClassFromString("UITextTapRecognizer")!
                // 原生输入框聚焦时, 再次点击会失焦
                if gesture.isKind(of: cls3) {
                    gesture.isEnabled = false
                    continue
                }
                gesture.cancelsTouchesInView = false
                gesture.delaysTouchesBegan = false
                gesture.delaysTouchesEnded = false
            }
        }
    }
}

extension WebView: UIGestureRecognizerDelegate {
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return false
    }

}

extension WKWebView {
    /// 通过containerId查找对应的滚动视图
    func isScrollViewFoundById(_ containerId: String, rootView: UIView) -> UIView? {
        let cls: AnyClass = NSClassFromString("WKCompositingView")!
        if rootView.isKind(of: cls) && rootView.description.contains(containerId) {
            let cls: AnyClass = NSClassFromString("WKChildScrollView")!
            guard let childScrollView = rootView.subviews.first, childScrollView.isKind(of: cls) else {
                return nil
            }
            return childScrollView
        }
        for subview in rootView.subviews {
            if let hit = isScrollViewFoundById(containerId, rootView: subview)  {
                return hit
            }
        }
        return nil
    }
    
    func findWebView(in view: UIView?) -> WKWebView? {
        guard let view = view else {
            return nil
        }
        if let webView = view as? WKWebView {
            return webView
        }
        // 递归查找父视图
        return findWebView(in: view.superview)
    }
}



extension WKWebView {
    // hook didMoveToWindow, 这里只hook WKChildScrollView
    static func swizzling() {
        DispatchQueue.once(token: "hook-didMoveToWindow") {
            let cls: AnyClass = NSClassFromString("WKChildScrollView")!
            // DidMoveToWindow在视图完全加入或者移除时调用
            let originalSelector = #selector(UIView.didMoveToWindow)
            let swizzledSelector = #selector(WKWebView.hookDidMoveToWindow)

            let originalMethod = class_getInstanceMethod(cls, originalSelector)!
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)!

            let didAddMethod = class_addMethod(cls, originalSelector,
                                                          method_getImplementation(swizzledMethod),
                                                          method_getTypeEncoding(swizzledMethod))
            guard didAddMethod else {
                method_exchangeImplementations(originalMethod, swizzledMethod)
                return
            }
            class_replaceMethod(cls, swizzledSelector,
                                           method_getImplementation(originalMethod),
                                           method_getTypeEncoding(originalMethod))
        }
    }
    
    /// WKChildScrollView ------>  didMoveToSuperview
    @objc func hookDidMoveToWindow() {
        self.hookDidMoveToWindow()
        // TODO ⚠️ id/class 过长会取不全显示...，暂时没有找到方法
        // ⚠️，此处要异步 🐷异步闭包在当前runloop完成之后排队等待运行🐷
        DispatchQueue.main.async { [self] in
            if let renderName = superview?.layer.name, renderName.contains("__tongceng_cid_")  {
                // 同层渲染场景
                // 从父视图的layer(层)的name(名称)中解析containerID(容器标识) eg: applets-container-id
                for gesture in self.gestureRecognizers ?? [] {
                    gesture.cancelsTouchesInView = false
                    gesture.delaysTouchesBegan = false
                    gesture.delaysTouchesEnded = false
                    self.removeGestureRecognizer(gesture)
                }
                guard let webView: WebView = findWebView(in: self) as? WebView else {
                    return
                }
                if (webView.sameLayerDelegate != nil) {
                    guard let tongcengId = self.getTongcengCidWithRenderName(renderName) else { return }
                    // TODO 是否校验tongcengId
                    // assert(!webView.tongcengNativeViews.keys.contains(tongcengId), "存在相同的tongcengId\(tongcengId)")
                    // 把WKChildScrollView缓存起来，方便下次查找
                    webView.tongcengContainers[tongcengId] = self
                    webView.sameLayerDelegate?.wKChildScrollViewdidMoveToWindow(childScrollView: self, tongcengId: tongcengId)
                }
                print(renderName)
            } else {
                // 非同层渲染场景
            }
        }
    }
    
    private func getTongcengCidWithRenderName(_ renderName: String) -> String? {
        do {
            let pattern = "__tongceng_cid_(.+)[ |']."
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(location: 0, length: renderName.utf16.count)
            if let match = regex.firstMatch(in: renderName, options: [], range: range) {
                let matchRange = Range(match.range(at: 1)  , in: renderName)!
                return renderName[matchRange].description.trimmingCharacters(in: .whitespaces)
            }
            return nil
        } catch {
            print("正则: \(error.localizedDescription)")
            return nil
        }
    }
}


extension WebView  {
    ///  插入
    /// - Parameter containerId: 容器ID
    func insertContainer(containerId: String, info: [String: String]) {
        var container = tongcengContainers[containerId]
        if (container == nil) {
            container = isScrollViewFoundById(containerId, rootView: self.scrollView)
        }
        // TODO 插入视频组件
        let lab = UILabel.init(frame: container!.bounds)
        lab.text = "TODO待插入组件"
        lab.backgroundColor = .red
        container!.addSubview(lab)
    }
    
    
    ///  回流更新
    /// - Parameter containerId: 容器ID
    func updateContainer(containerId: String, info: [String: String]) {
    }
}
