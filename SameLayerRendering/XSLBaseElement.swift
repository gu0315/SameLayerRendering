//
//  XSLBaseElement.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/26.
//

import UIKit
import WebKit
import Foundation

//方法名必须以xsl__开头, observedAttributes
//eg:添加事件 func xsl__play(_ args: Dictionary) {}
//eg:添加带callback属性 func xsl__play(_ args: Dictionary, callback: BridgeCallBack) {}
class XSLBaseElement: NSObject {
    
    required override init() {
        super.init()
    }
    
    weak var webView: WKWebView? {
        get {
            if _webView == nil {
                _webView = self.findWebView(in: self.containerView)
            }
            return _webView
        }
        set {
            _webView = newValue
        }
    }
    
    private weak var _webView: WKWebView?
    
    weak var weakWKChildScrollView: UIView?
    
    var rendering = false
    
    var isAddToSuper = false
    
    var class_name: String = ""
    
    var attributes: Dictionary<String, Any> = [:]
    
    var size: CGSize = .zero
    
    static var xslBaseElementJsKey = "xslBaseElementJsKey"
    
    @objc class func jsClass() -> String {
        withUnsafePointer(to: &XSLBaseElement.xslBaseElementJsKey) { pointer in
            guard let js: String = objc_getAssociatedObject(self, pointer) as? String else {
                let jsClass = self.createJSClass()
                objc_setAssociatedObject(self, pointer, jsClass, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                return jsClass
            }
            return js
        }
    }
    
    lazy var containerView: ContainerHookView = {
        let view = ContainerHookView.init(frame: .zero)
        view.isUserInteractionEnabled = true
        return view
    }()
    
    func setClassName(_ name: String) {
        class_name = name
    }

    @objc class func createJSClass() -> String {
        let elementName = elementName()
        if elementName.isEmpty { return "" }
        if ((XSLManager.sharedSLManager.jsMap[elementName]) != nil) {
            return XSLManager.sharedSLManager.jsMap[elementName]!
        }
        var js = hybridHookXSLJS()
        // 处理 elementName，将其中的横杠替换为驼峰式命名
        var elementClassName = ""
        let elementNameComponents = elementName.components(separatedBy: "-")
        elementNameComponents.enumerated().forEach { (idx, obj) in
            elementClassName.append(obj.capitalized)
        }
        js = js.replacingOccurrences(of: "$ElementName", with: elementClassName)
        js = js.replacingOccurrences(of: "$Element-Name", with: elementName)
        // 公共默认观察的属性
        var observers = ["class", "hidden"]
        var count: UInt32 = 0
        // 获取类的方法列表
        guard let methodList = class_copyMethodList(self, &count) else {
            return js
        }
        for i in 0..<Int(count) {
            let method = methodList[i]
            let methodStr = NSStringFromSelector(method_getName(method))
            if methodStr.hasPrefix("xsl__") {
                var observerVal = String(methodStr.suffix(methodStr.count - 5))
                if (observerVal.last == ":") {
                    observerVal = String(observerVal.dropLast())
                }
                if observerVal.contains("_") {
                    let newObserver = observerVal.replacingOccurrences(of: "_", with: "-")
                    observers.append(newObserver)
                } else {
                    if let firstUppercase = isExistUppercaseString(in: observerVal) {
                        observerVal = getSnakeCaseFromCamelCase(String(firstUppercase)) + observerVal
                    }
                }
                observerVal = observerVal.replacingOccurrences(of: ":callback", with: "")
                observers.append(String(observerVal))
            }
        }
        // 替换 JavaScript 代码中的占位符
        js = js.replacingOccurrences(of: "$obsevers", with: observers.joined(separator: "','"))
        // 将最终的 JavaScript 代码保存到 map 中
        XSLManager.sharedSLManager.jsMap[elementName] = js
        return js
    }
    
    @objc class func generateFunctions(_ functions: [String]) -> String {
        var functionStr = ""
        functions.forEach { functionName in
            functionStr += """
                \(functionName): function(params, callbackName, callbackId) {
                    this.messageToNative({
                        methodType: 'invokeXslNativeMethod',
                        methodName: '\(functionName)',
                        args: params,
                        callbackName: callbackName,
                        callbackId: callbackId
                    });
                },
            """
        }
        return functionStr
    }

    func setWebView(_ view: WKWebView) {
        webView = view
    }
    
    func findWebView(in view: UIView?) -> WKWebView? {
         if (self.webView != nil) {
             return self.webView
         }
         guard let view = view else { return nil }
         if let webView = view as? WKWebView {
             return webView
         }
         return findWebView(in: view.superview)
     }
    
    @objc func setSize(_ size: CGSize) {
        self.size = size
        containerView.frame = .init(x: 0, y: 0, width: size.width, height: size.height)
        if (size.height > 0 && !self.rendering) {
            rendering = true
        }
    }

    @objc class func elementName() -> String {
        return String()
    }
    
    @objc func elementConnected(_ params: [String: Any]) {
        attributes = params
    }
    
    @objc func removeFromSuperView() {
        self.containerView.removeFromSuperview()
    }
    
    @objc func addToWKChildScrollView() {
        self.weakWKChildScrollView?.addSubview(self.containerView)
    }

    class func isElementValid() -> Bool {
        return true
    }
    
    @objc class func getSnakeCaseFromCamelCase(_ oriStr: String) -> String {
        var str = oriStr
        while let upperRange = str.rangeOfCharacter(from: .uppercaseLetters) {
            let startIndex = upperRange.lowerBound
            let endIndex = upperRange.upperBound
            let char = str[startIndex]
            let replacement = "_\(char.lowercased())"
            str.replaceSubrange(startIndex..<endIndex, with: replacement)
        }
        return str
    }
    
    ///  判断是否还存在大写字母
    @objc class func isExistUppercaseString(in str: String) -> String? {
        for char in str {
            if char.isUppercase {
                return String(char)
            }
        }
        return nil
    }
}
