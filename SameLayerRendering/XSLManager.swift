//
//  XSLManager.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/26.
//

import UIKit
import WebKit
import ObjectiveC

struct AssociatedKeys  {
    // 用于设置WKCompositingView关联的Native组件
    static var hybridXSLElementKey = "hybridXSLElementKey"
    static var hybridXSLElementMapKey = "hybridXSLElementMapKey"
    static var hybridXSLDidFinishHandleWKContentGestureKey = "hybridXSLDidFinishHandleWKContentGestureKey"
}

class XSLManager: NSObject {
    
    static public let sharedSLManager = XSLManager()
    
    /// 用于H5元素到Native的映射, key表示H5元素， value表示替换成Native组建
    var elementsClassMap: [String: AnyClass] = [:]

    ///  注入的Js WebComponent
    var jsMap:Dictionary<String, String> = [:]
    
    /// 客户端支持的h5组件
    var availableElementArrs: [String] {
        get {
            var availableElementArrs = Array<String>()
            for key in XSLManager.sharedSLManager.elementsClassMap.keys {
                if let obj = XSLManager.sharedSLManager.elementsClassMap[key] as? XSLBaseElement.Type  {
                    if (obj.isElementValid()) {
                        availableElementArrs.append(key)
                    }
                }
                
            }
            return availableElementArrs
        }
    }
    
    private override init() {
        super.init()
        // swift 不支持__attribute动态化，可以考虑objc_copyClassList匹配协议找到支持的组件, 这里考虑到组件少，及获取objc_copyClassList性能问题，手动配置
        // self.readXslRegisteredElement()
        elementsClassMap = ["hybrid-image": XImageElement.self, 
                            "hybrid-video": XVideoElement.self,
                            "hybrid-input": XInputElement.self]
    }
    
    /*private func readXslRegisteredElement() {
        if ((elementsClassMap.count) != 0) {
            return
        }
        var count: UInt32 = 0
        let classList = objc_copyClassList(&count)!
        defer { free(UnsafeMutableRawPointer(classList)) }
        let classes = UnsafeBufferPointer(start: classList, count: Int(count))
        var tmpCache: Dictionary<String, AnyClass> = [:]
        for cls in classes {
            if (class_conformsToProtocol(cls, HybridXSLRegisterClassProtocol.self)) {
                if cls.responds(to: Selector.init(("elementName"))) {
                    guard let obj = cls as? NSObject.Type else { return }
                    let elementName = obj.perform(Selector.init(("elementName")))?.takeUnretainedValue() as? String
                    if (elementName != nil) {
                        tmpCache[elementName!] = cls
                    }
                }
            }
        }
        elementsClassMap = tmpCache
    }*/
    
    public func initSLManagerWithWebView(_ wKWebView: WKWebView) {
        wKWebView.xslElementMap = [:]
        if (XSLManager.sharedSLManager.isHybridXslValid())  {
            wKWebView.addUserScript()
            wKWebView.addElementAvailableUserScript()
            XSLManager.sharedSLManager.hookWebview()
            
        }
        // MARK: - 禁止点击文本交互，放大镜
        if #available(iOS 14.5, *) {
            wKWebView.configuration.preferences.isTextInteractionEnabled = false
        } else {
            let selectionScript = WKUserScript(source: """
                        document.body.style.webkitTouchCallout='none';
                        document.body.style.webkitUserSelect='none';
                    """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            wKWebView.configuration.userContentController.addUserScript(selectionScript)
        }
        // MARK: - 禁止点击图片放大
        let source = """
              var style = document.createElement('style');
              style.innerHTML = 'img { pointer-events: none; }';
              document.head.appendChild(style);
        """
        let selectionScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        wKWebView.configuration.userContentController.addUserScript(selectionScript)
    }
    
    func isHybridXslValid() -> Bool {
        var isHybridXslValid = true
        if XSLManager.sharedSLManager.availableElementArrs.count == 0 || NSClassFromString("WKChildScrollView") == nil || NSClassFromString("WKCompositingView") == nil {
            isHybridXslValid = false
        }
        return isHybridXslValid
    }
    
    
    func imp(old: inout IMP?, cls: AnyClass, sel: Selector, imp: Any) {
        let newImp = imp_implementationWithBlock(imp)
        guard let method = class_getInstanceMethod(cls, sel) else { return }
        old = method_getImplementation(method)
        // 添加方法
        let didAddMethod = class_addMethod(cls, sel, newImp, method_getTypeEncoding(method))
        if !didAddMethod {
            // 将新的方法实现设置给method
            old = method_setImplementation(method, newImp)
        }
    }

    func hookWebview() {
        DispatchQueue.once(token: "XSLManager-HookWebview") {
            // Hook setScrollEnabled
            if let cls: AnyClass = NSClassFromString("WKChildScrollView") {
                let oldSel = Selector(("setScrollEnabled:"))
                var oldImp: IMP? = nil
                typealias type = @convention(block) (UIScrollView, Selector, Bool) -> Void
                let blockImplementation: type = { [weak self] obj, sel, isEnable in
                    guard let self = self else { return }
                    typealias ClosureType = @convention(c) (UIScrollView, Selector, Bool) -> Void
                    let oldMethod: ClosureType = unsafeBitCast(oldImp, to: ClosureType.self)
                    let element: XSLBaseElement? = self.getBindElement(obj.superview, name: obj.superview?.layer.name)
                    if (element != nil) {
                        oldMethod(obj, oldSel, false)
                    } else{
                        oldMethod(obj, oldSel, isEnable);
                    }
                }
                self.imp(old: &oldImp, cls: cls, sel: oldSel, imp: blockImplementation)
            }
            // Hook setContentSize
            if let cls: AnyClass = NSClassFromString("WKChildScrollView") {
                let oldSel = Selector(("setContentSize:"))
                var oldImp: IMP? = nil
                typealias type = @convention(block) (UIScrollView, Selector, CGSize) -> Void
                let blockImplementation: type = { [weak self] obj, sel, contentSize in
                    guard let self = self else { return }
                    typealias ClosureType = @convention(c) (UIScrollView, Selector, CGSize) -> Void
                    let oldMethod: ClosureType = unsafeBitCast(oldImp, to: ClosureType.self)
                    oldMethod(obj, oldSel, contentSize)
                    self.getBindElement(obj.superview, name: obj.superview?.layer.name)
                }
                self.imp(old: &oldImp, cls: cls, sel: oldSel, imp: blockImplementation)
            }
            // Hook removeFromSuperview
            if let cls: AnyClass = NSClassFromString("WKChildScrollView") {
                let oldSel = #selector(UIView.removeFromSuperview)
                var oldImp: IMP? = nil
                typealias type = @convention(block) (UIScrollView, Selector) -> Void
                let blockImplementation: type = { obj, sel in
                    withUnsafePointer(to: &AssociatedKeys.hybridXSLElementKey) { ptr in
                        let element: XSLBaseElement? = objc_getAssociatedObject(obj.superview!, ptr) as? XSLBaseElement
                        if (element != nil) {
                            print("同层渲染-element->remove", element!)
                            element!.isAddToSuper = false
                            element!.removeFromSuperView()
                        }
                    }
                    typealias ClosureType = @convention(c) (UIScrollView, Selector) -> Void
                    let oldMethod: ClosureType = unsafeBitCast(oldImp, to: ClosureType.self)
                    oldMethod(obj, oldSel)
                }
                self.imp(old: &oldImp, cls: cls, sel: oldSel, imp: blockImplementation)
            }
        }
    }
    
    
    /// 核心方法，通过name查找视图
    @discardableResult
    func getBindElement(_ view: UIView? , name: String?) -> XSLBaseElement? {
        guard let name = name, let view = view else { return nil }
        if let wkCompositingViewType = NSClassFromString("WKCompositingView"), view.isKind(of: wkCompositingViewType), name.contains("class") {
            var element: XSLBaseElement?
            withUnsafePointer(to: &AssociatedKeys.hybridXSLElementKey) { pointer in
                element = objc_getAssociatedObject(view, pointer) as? XSLBaseElement
            }
            if (element != nil) {
                return element
            }
            // 待优化 eg: name中包含‘
            let divClass: [String] = name.components(separatedBy: "class=").last?.components(separatedBy: "'")[1]
                .trimmingCharacters(in: .init(charactersIn: "'")).components(separatedBy: " ") ?? []
            guard let webView: WKWebView = self.findWebView(in: view) else {
                // ⚠️，此处要异步 🐷异步闭包在当前runloop完成之后排队等待运行🐷
                print("==wait==")
                DispatchQueue.main.async {
                    self.getBindElement(view, name: name)
                }
                return nil
            }
            if (webView.xslElementMap == nil) { return nil }
            for key in divClass {
                if let el = webView.xslElementMap?[key] as? XSLBaseElement {
                    element = el
                    el.setWebView(webView)
                    el.setSize(view.frame.size)
                    withUnsafePointer(to: &AssociatedKeys.hybridXSLElementKey) { pointer in
                        objc_setAssociatedObject(view, pointer, el, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    }
                    break
                }
            }
            self.addElement(element: element, toSuperView: view.subviews.last!)
            return element
        }
        return nil
    }

    func addElement(element: XSLBaseElement?, toSuperView: UIView) {
        guard let element = element else {
            return
        }
        if !element.isAddToSuper && toSuperView.isKind(of: NSClassFromString("WKChildScrollView")!) {
            element.isAddToSuper = true
            element.weakWKChildScrollView = toSuperView
            element.addToWKChildScrollView()
        }
        print("同层渲染-element->add", element)
    }
    
    func findWebView(in view: UIView?) -> WKWebView? {
        guard let view = view else { return nil }
        if let webView = view as? WKWebView {
            return webView
        }
        return findWebView(in: view.superview)
    }
    
    override func copy() -> Any {
        return self
    }

    override func mutableCopy() -> Any {
        return self
    }
}


extension WKWebView {
    
    /// hitTest拦截
    var isFinishHandleWKContentGesture: Bool? {
        get {
            withUnsafePointer(to: &AssociatedKeys.hybridXSLDidFinishHandleWKContentGestureKey) { pointer in
                return objc_getAssociatedObject(self, pointer) as? Bool
            }
        }
        set {
            withUnsafePointer(to: &AssociatedKeys.hybridXSLDidFinishHandleWKContentGestureKey) { pointer in
                objc_setAssociatedObject(self, pointer, newValue, .OBJC_ASSOCIATION_ASSIGN)
            
            }
        }
    }
    
    /// h5 Key: Native  h5标签映射到原生组件实例 eg: ["hybrid-image0":  XImageElement]
    var xslElementMap: Dictionary<String, AnyObject>? {
        get {
            withUnsafePointer(to: &AssociatedKeys.hybridXSLElementMapKey) { pointer in
                return objc_getAssociatedObject(self, pointer) as? Dictionary
            }
        }
        set {
            withUnsafePointer(to: &AssociatedKeys.hybridXSLElementMapKey) { pointer in
                objc_setAssociatedObject(self, pointer, newValue, .OBJC_ASSOCIATION_COPY)
            }
        }
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if !(isFinishHandleWKContentGesture ?? false) {
            handleWKContentGestures()
            isFinishHandleWKContentGesture = true
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

    /// 拦截手势
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
    
    /// Web Components 是否支持同层
    func addElementAvailableUserScript() {
        var keyString = NSMutableString()
        for key in XSLManager.sharedSLManager.availableElementArrs {
            keyString.append("'\(key)',")
        }
        if keyString.length > 0 {
            keyString = NSMutableString(string: keyString.substring(to: keyString.length - 1))
        }
        let keyArrString = "[\(keyString)]"
        let scriptSource = """
        ;(function(){
            if (window.XWidget === undefined) {
                window.XWidget = {};
                window.XWidget.canIUse = function canUseXSL(name) {
                    var registerElements = \(keyArrString);
                    if (registerElements.indexOf(name) == -1) {
                        return false;
                    } else {
                        return true;
                    }
                };
            }
        })();
        """
        let script = WKUserScript(source: scriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        self.configuration.userContentController.addUserScript(script)
    }
    
    /// 核心方法，注入Web Components, 添加 overflow:scroll; -webkit-overflow-scrolling: touch;
    func addUserScript() {
        XSLManager.sharedSLManager.elementsClassMap.forEach { (key: String, cls: AnyClass) in
            let sel: Selector = Selector.init(("jsClass"))
            guard let obj = cls as? NSObject.Type else { return }
            guard obj.responds(to: sel) else { return }
            if  let jsClass = obj.perform(sel)?.takeUnretainedValue() as? String {
                let script = WKUserScript(source: jsClass, injectionTime: .atDocumentStart, forMainFrameOnly: false)
                self.configuration.userContentController.addUserScript(script)
            }
        }
    }
}

