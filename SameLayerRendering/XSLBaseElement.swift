//
//  XSLBaseElement.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/26.
//

import UIKit
import WebKit
import Foundation

//方法名以xsl开头
//eg:添加事件 func xsl_play(args: Dictionary) {}
//eg:添加又返回值的事件 func xsl_callback_play(args: Dictionary) -> String {}
//eg:带两个参数的 arg  & callback func xsl_callback_play(args: String,  callback: BridgeCallBack) -> String {}
//eg:添加属性 func xsl__url(args: Dictionary) {}
//eg:添加带callback属性 func xsl__url(args: Dictionary, callback: BridgeCallBack) {}
class XSLBaseElement: NSObject {
    
    override init() {
        super.init()
        print("init----XSLBaseElement")
    }
    
    var webView: WKWebView?
    
    var weakWKChildScrollView: UIView?
    
    var rendering = false
    
    var isAddToSuper = false
    
    var class_name: String = ""
    
    private var _size: CGSize = .zero
    
    private var style: Dictionary<String, String> = [:]
    
    private var xslStyle: Dictionary<String, String> = [:]
    
    static let xslBaseElementJsKey = "xslBaseElementJsKey"
    
    @objc func jsClass() -> String {
        guard let js: String = objc_getAssociatedObject(self, XSLBaseElement.xslBaseElementJsKey) as? String else {
            let jsClass = createJSClass()
            objc_setAssociatedObject(self, XSLBaseElement.xslBaseElementJsKey, jsClass, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return jsClass
        }
        return js
    }
    
    lazy var containerView: ContainerHookView = {
        let view = ContainerHookView.init(frame: .zero)
        if (responds(to: #selector(nativeElementInteraction))) {
            view.nativeElementInteractionEnabled = nativeElementInteraction()
        }
        view.isUserInteractionEnabled = true
        return view
    }()
    
    func setClassName(_ name: String) {
        class_name = name
    }
   
   @objc func createJSClass() -> String {
        let elementName = self.elementName()
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
        // 获取类的方法列表
        var functions = [String]()
        var observers = ["style", "xsl_style", "class", "hidden", "hybrid_xsl_id"]
        var count: UInt32 = 0
       guard let methodList = class_copyMethodList(self.classForCoder, &count) else { return js }
        for i in 0..<Int(count) {
            let method = methodList[i]
            let methodStr = NSStringFromSelector(method_getName(method))
            print(methodStr)
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
            } else if methodStr.hasPrefix("xsl_") {
                // TODO
                var rmXslStr = String(methodStr.suffix(methodStr.count - 4))
                rmXslStr = rmXslStr.replacingOccurrences(of: ":", with: "__")
                functions.append(String(rmXslStr))
            }
        }
        // 替换 JavaScript 代码中的占位符
        js = js.replacingOccurrences(of: "$obsevers", with: observers.joined(separator: "','"))
        js = js.replacingOccurrences(of: "$customfunction", with: generateFunctions(functions))
        // 将最终的 JavaScript 代码保存到 map 中
        XSLManager.sharedSLManager.jsMap[elementName] = js
        return js

    }
    
    
    func generateFunctions(_ functions: [String]) -> String {
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
    
    @objc func setSize(_ size: CGSize) {
        _size = size
        containerView.frame = .init(x: 0, y: 0, width: size.width, height: size.height)
        if (size.height > 0 && !self.rendering) {
            rendering = true
            elementRendered()
        }
    }
    
    @objc func setStyleString(_ style: String) {
        var stylesMap = [String: String]()
        let styles = style.components(separatedBy: ";")
        styles.forEach { stylePair in
            let keyValues = stylePair.components(separatedBy: ":")
            if keyValues.count > 1 {
                let key = keyValues[0].trimmingCharacters(in: .whitespaces)
                if !key.isEmpty {
                    let value = keyValues[1].trimmingCharacters(in: .whitespaces)
                    if !value.isEmpty {
                        stylesMap[key] = value
                    }
                }
            }
        }
        self.style = stylesMap
    }

    @objc func setXSLStyleString(_ style: String) {
        var stylesMap = [String: String]()
        let styles = style.components(separatedBy: ";")
        styles.forEach { stylePair in
            let keyValues = stylePair.components(separatedBy: ":")
            if keyValues.count > 1 {
                let key = keyValues[0].trimmingCharacters(in: .whitespaces)
                if !key.isEmpty {
                    let value = keyValues[1].trimmingCharacters(in: .whitespaces)
                    if !value.isEmpty {
                        stylesMap[key] = value
                    }
                }
            }
        }
        xslStyle = stylesMap
    }

    @objc func elementName() -> String {
        return ""
    }
    
    @objc func elementConnected() {
        
    }
    
    @objc func elementRendered() {
        
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
    
    // 原生同层渲染组件是否响应事件，默认关闭
    @objc func nativeElementInteraction() -> Bool {
        return false
    }
    
    func getSnakeCaseFromCamelCase(_ oriStr: String) -> String {
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
    func isExistUppercaseString(in str: String) -> String? {
        for char in str {
            if char.isUppercase {
                return String(char)
            }
        }
        return nil
    }
}
