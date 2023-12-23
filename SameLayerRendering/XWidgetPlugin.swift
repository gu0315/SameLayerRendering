//
//  XWidgetPlugin.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/26.
//

import UIKit

class XWidgetPlugin: NSObject {
    
    required override init() {
        super.init()
    }
    
    @discardableResult
    @objc func execute(action: String, params: [String: Any], jsBridgeCallback: JSBridgeCallBack) -> Bool {
        let selectorString = "\(action)WithElementIdWithTheId:params:jsBridgeCallback:"
        debugPrint("同层渲染Web Components->生命周期回调", params["xsl_id"] ?? "", action)
        if responds(to: Selector(selectorString)) {
            let selector = Selector(selectorString)
            if let method = class_getInstanceMethod(type(of: self), selector) {
                typealias Function = @convention(c) (AnyObject, Selector, String, [String: Any], JSBridgeCallBack) -> Void
                let function = unsafeBitCast(method_getImplementation(method), to: Function.self)
                guard let theId = params["xsl_id"] as? String else {
                    self.inValidBridgeCallBack(jsBridgeCallback: jsBridgeCallback, message: "not found plugin")
                    return false
                }
                function(self, selector, theId, params, jsBridgeCallback)
            }
        } else {
            guard let theId = params["xsl_id"] as? String else {
                self.inValidBridgeCallBack(jsBridgeCallback: jsBridgeCallback, message: "not found plugin")
                return false
            }
            invokeXslNativeMethodWithElementId(theId: theId, params: params, jsBridgeCallback: jsBridgeCallback)
        }
        return true
    }
    
    @discardableResult
    func inValidBridgeCallBack(jsBridgeCallback: JSBridgeCallBack, message: String) -> Bool {
        if ((jsBridgeCallback.onFail) != nil) {
            jsBridgeCallback.onFail!(NSError(domain: NSCocoaErrorDomain,
                                            code: -2,
                                            userInfo: [NSLocalizedDescriptionKey: message]))
        }
        return false
    }
    
    // MARK: - Web Components to constructor
    @objc func createXslWithElementId(theId: String, params: [String: Any], jsBridgeCallback: JSBridgeCallBack) {
        guard let element = XSLManager.sharedSLManager
            .elementsClassMap[theId.trimmingCharacters(in: CharacterSet.decimalDigits)] as? XSLBaseElement.Type else {
            return
        }
        let v = element.init()
        v.setClassName(theId)
        if (jsBridgeCallback.message?.webView != nil) {
            v.setWebView((jsBridgeCallback.message?.webView)!)
        }
        var tempDic: Dictionary<String, AnyObject> = jsBridgeCallback.message?.webView?.xslElementMap ?? [:]
        tempDic[theId] = v
        jsBridgeCallback.message?.webView?.xslElementMap = tempDic
    }
    
    // MARK: - Web Components to attributeChangedCallback
    @objc func changeXslWithElementId(theId: String, params: [String: Any], jsBridgeCallback: JSBridgeCallBack) {
        if let name = params["methodName"] as? String, let element = jsBridgeCallback.message?.webView?.xslElementMap?[theId] as? XSLBaseElement {
            switch name {
            case "class", "hidden":
                // TODO: 暂不处理
                break
            default:
                let sel = NSSelectorFromString("xsl__\(name):")
                if element.responds(to: sel) {
                   element.perform(sel, with: params)
                }
                if params["callbackName"] is String {
                    // 属性函数事件
                    let selCallback = NSSelectorFromString("xsl__\(name):callback:")
                    if element.responds(to: selCallback) {
                        element.perform(selCallback, with: params["args"], with: jsBridgeCallback)
                    }
                }
                break
            }
        }
    }
    
    // MARK: - Web Components to connectedCallback
    @objc func addXslWithElementId(theId: String, params: [String: Any], jsBridgeCallback: JSBridgeCallBack) {
        guard let element = jsBridgeCallback.message?.webView?.xslElementMap?[theId] as? XSLBaseElement else {
            self.createXslWithElementId(theId: theId, params: params, jsBridgeCallback: jsBridgeCallback)
            if let v = jsBridgeCallback.message?.webView?.xslElementMap?[theId] as? XSLBaseElement {
                v.elementConnected(params)
            }
            return
        }
        element.elementConnected(params)
    }
    
    // MARK: - Web Components to disconnectedCallback
    @objc func removeXslWithElementId(theId: String, params: [String: Any], jsBridgeCallback: JSBridgeCallBack) {
        var tempDic = jsBridgeCallback.message?.webView?.xslElementMap
        tempDic?[theId] = nil
        jsBridgeCallback.message?.webView?.xslElementMap = tempDic
    }
    
    // MARK: - Web Components 调用 Native组件具体发法
    @objc func invokeXslNativeMethodWithElementId(theId: String, params: [String: Any], jsBridgeCallback: JSBridgeCallBack) {
        let theId = theId
        guard let methodName = params["methodName"] as? String else {
            return
        }
        let argsParams = params["args"]
        if let element = jsBridgeCallback.message?.webView?.xslElementMap?[theId] as? XSLBaseElement {
            let selector = NSSelectorFromString("xsl__\(methodName):")
            let selectorCallback = NSSelectorFromString("xsl__\(methodName):callback:")
            if element.responds(to: selector) {
                element.perform(selector, with: argsParams)
            } else if element.responds(to: selectorCallback) {
                element.perform(selectorCallback, with: argsParams, with: jsBridgeCallback)
            } else {
                print("暂未实现\(selector)和\(selectorCallback)方法,可能Web Components端调用错误")
            }
        }
    }
}

