//
//  XWidgetPlugin.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/26.
//

import UIKit

class XWidgetPlugin: NSObject {
    
    @discardableResult
    @objc func execute(action: String, params: [String: Any], jsBridgeCallback: BridgeCallBack) -> Bool {
        setXslIdMapDic(dic: params, jsBridgeCallback: jsBridgeCallback)
        
        let selectorString = "\(action)WithElementIdWithTheId:params:jsBridgeCallback:"
        print(selectorString)
//        var count: UInt32 = 0
//        guard let methodList = class_copyMethodList(self.classForCoder, &count) else { return true }
//        for i in 0..<Int(count) {
//            let method = methodList[i]
//            let methodStr = NSStringFromSelector(method_getName(method))
//            print(methodStr)
//        }
        if responds(to: Selector(selectorString)) {
            let selector = Selector(selectorString)
            if let method = class_getInstanceMethod(type(of: self), selector) {
                typealias Function = @convention(c) (AnyObject, Selector, String, [String: Any], BridgeCallBack) -> Void
                let function = unsafeBitCast(method_getImplementation(method), to: Function.self)
                guard let theId = params["xsl_id"] as? String else { return true }
                function(self, selector, theId, params, jsBridgeCallback)
            }
        } else {
            guard let theId = params["xsl_id"] as? String else { return true }
            invokeXslNativeMethodWithElementId(theId: theId, params: params, jsBridgeCallback: jsBridgeCallback)
        }
        return true
    }
    
    @objc func addXslWithElementId(theId: String, params: [String: Any], jsBridgeCallback: BridgeCallBack) {
        guard let element = jsBridgeCallback.message?.webView?.xslElementMap?[theId] as? XSLBaseElement else {
            self.createXslWithElementId(theId: theId, params: params, jsBridgeCallback: jsBridgeCallback)
            if let v = jsBridgeCallback.message?.webView?.xslElementMap?[theId] as? XSLBaseElement {
                v.elementConnected()
            }
            return
        }
        element.elementConnected()
    }

    @objc func createXslWithElementId(theId: String, params: [String: Any], jsBridgeCallback: BridgeCallBack) {
        guard let element = XSLManager.sharedSLManager
            .elementsClassMap[theId.trimmingCharacters(in: CharacterSet.decimalDigits)] as? NSObject.Type else {
            return
        }
        guard let v = element.init() as? XSLBaseElement else { return }
        v.setClassName(theId)
        var tempDic = jsBridgeCallback.message?.webView?.xslElementMap
        tempDic?[theId] = v
        jsBridgeCallback.message?.webView?.xslElementMap = tempDic
    }

    @objc func invokeXslNativeMethodWithElementId(theId: String, params: [String: Any], jsBridgeCallback: BridgeCallBack) {
        var theId = theId
        var methodName = params["methodName"] as? String
        var argsParams = params["args"]
        if let hybridXslId = params["hybrid_xsl_id"] as? String {
            if let xslIdMap = jsBridgeCallback.message?.webView?.xslIdMap, let xslId = xslIdMap[hybridXslId] as? String {
                theId = xslId
                methodName = params["functionName"] as? String
                argsParams = params
            }
        }
        
        if let element = jsBridgeCallback.message?.webView?.xslElementMap?[theId] as? XSLBaseElement {
            let selectorCallback = NSSelectorFromString("xsl_callback_\(methodName ?? ""):")
            let selector = NSSelectorFromString("xsl_\(methodName ?? ""):")
            let selectorCallbackArgs = NSSelectorFromString("xsl_callback_\(methodName ?? ""):callback:")
            if element.responds(to: selectorCallback) {
                element.perform(selectorCallback, with: argsParams, with: jsBridgeCallback)
            } else if element.responds(to: selectorCallbackArgs) {
                element.perform(selectorCallbackArgs, with: argsParams, with: jsBridgeCallback)
            } else if element.responds(to: selector) {
                typealias ClosureType = @convention(c) (XSLBaseElement, Selector, Any) -> Void
                let oldMethod: ClosureType = unsafeBitCast(class_getMethodImplementation(type(of: element), selector), to: ClosureType.self)
                oldMethod(element, selector, argsParams ?? "")
//                if let onSuccess = jsBridgeCallback.onSuccess {
//                    onSuccess(argsParams)
//                }
            }
        }
    }

    @objc func changeXslWithElementId(theId: String, params: [String: Any], jsBridgeCallback: BridgeCallBack) {
        print("------")
        if let name = params["methodName"] as? String, let element = jsBridgeCallback.message?.webView?.xslElementMap?[theId] as? XSLBaseElement {
            if name == "style" {
                element.setStyleString(params["newValue"] as? String ?? "")
            } else if name == "xsl_style" {
                element.setXSLStyleString(params["newValue"] as? String ?? "")
            } else {
                var sel = NSSelectorFromString("xsl__\(name):")
                if !element.responds(to: sel) {
                    var newName = ""
                    let nameArr = name.components(separatedBy: "-")
                    if nameArr.count > 1 {
                        newName = nameArr.joined(separator: "_")
                        sel = NSSelectorFromString("xsl__\(newName):")
                    }
                }
                if !element.responds(to: sel) {
                    var newName = ""
                    let nameArr = name.components(separatedBy: "_")
                    if nameArr.count > 1 {
                        newName = getCamelCaseFromSnakeCase(oriStr: name)
                        sel = NSSelectorFromString("xsl__\(newName):")
                    }
                }
                if element.responds(to: sel) {
                    typealias ClosureType = @convention(c) (XSLBaseElement, Selector, Dictionary<String, Any>) -> Void
                    let oldMethod: ClosureType = unsafeBitCast(class_getMethodImplementation(type(of: element), sel), to: ClosureType.self)
                    oldMethod(element, sel, params)
                }
//                if let callbackName = params["callbackName"] as? String {
//                    // 属性 函数事件
//                    let selCallback = NSSelectorFromString("xsl__\(name):callback:")
//                    if element.responds(to: selCallback) {
//                        element.perform(selCallback, with: params["args"], with: jsBridgeCallback)
//                    }
//                }
            }
        }
    }

    @objc func getCamelCaseFromSnakeCase(oriStr: String) -> String {
        var str = oriStr
        while str.contains("_") {
            if let range = str.range(of: "_") {
                let index = str.index(range.lowerBound, offsetBy: 1)
                let c = str[index].uppercased()
                str.replaceSubrange(range, with: c)
            }
        }
        return str
    }

    @objc func removeXslWithElementId(theId: String, params: [String: Any], jsBridgeCallback: BridgeCallBack) {
        var tempDic = jsBridgeCallback.message?.webView?.xslElementMap
        tempDic?[theId] = nil
        jsBridgeCallback.message?.webView?.xslElementMap = tempDic
    }

    @objc func setXslIdMapDic(dic: [String: Any], jsBridgeCallback: BridgeCallBack) {
   
        var tempDic: Dictionary<String, String> = [:]
        guard  let hybridXslId = dic["hybrid_xsl_id"] as? String,
               let xslId = dic["xsl_id"] as? String else { return }
        tempDic[hybridXslId] = xslId
        jsBridgeCallback.message?.webView?.xslIdMap = tempDic 
    }
}

