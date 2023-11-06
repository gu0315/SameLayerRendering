//
//  JSBridge.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/9/11.
//

import UIKit
import WebKit

class JSBridgeManager: NSObject {
    
    private weak var bridgeWebView: WKWebView?
    
    let KInjectJS = ";(function(){if(window.XWebView===undefined){window.XWebView={};window.XWebView.callNative=function(module,method,params,callbackName,callbackId){window.webkit.messageHandlers.XWebView.postMessage({'plugin':module,'method':method,'params':params,'callbackName':callbackName,'callbackId':callbackId})};window.XWebView._callNative=function(jsonstring){window.webkit.messageHandlers.XWebView.postMessage(jsonstring)}}})();"
    
    public init(_ bridgeWebView: WKWebView?) {
        super.init()
        self.bridgeWebView = bridgeWebView
        self.bridgeWebView?.configuration.userContentController.removeScriptMessageHandler(forName: "XWebView")
        let weakScriptMessageDelegate = WeakScriptMessageDelegate.init(delegate: self)
        self.bridgeWebView?.configuration.userContentController.add(weakScriptMessageDelegate, name: "XWebView")
        let script = WKUserScript(source: KInjectJS, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        self.bridgeWebView?.configuration.userContentController.addUserScript(script)
    }
    
    deinit {
        self.bridgeWebView?.configuration.userContentController.removeScriptMessageHandler(forName: "XWebView")
    }
}

extension JSBridgeManager: WKScriptMessageHandler {
    //  JS Call Native
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {}
}

class WeakScriptMessageDelegate: NSObject, WKScriptMessageHandler {
    
    private weak var delegate: WKScriptMessageHandler?
    
    private var _userContentController: WKUserContentController?
    
    var bridgePluginMap: Dictionary<String, AnyObject> = [:]
    
    init(delegate: WKScriptMessageHandler?) {
       self.delegate = delegate
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(userContentController, didReceive: message)
        self._userContentController = userContentController
        if (Thread.isMainThread) {
            self.invokeJsMethodWithMessage(message)
        } else {
            DispatchQueue.main.async {
                self.invokeJsMethodWithMessage(message)
            }
        }
    }
    
    func invokeJsMethodWithMessage(_  message: WKScriptMessage) {
        guard let dict = message.body as? Dictionary<String, Any> else { return }
        let pluginName = dict["plugin"] as? String ?? ""
        let method = dict["method"] as? String ?? dict["action"] as? String ?? ""
        let params = dict["params"] as? [String: Any] ?? [:]
        let _ = dict["callbackName"] as? String ?? ""
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
        let callback = JSBridgeCallBack.callback
        callback.message = message
        if let plugin: XWidgetPlugin = bridgePluginMap[pluginName] as? XWidgetPlugin  {
            plugin.execute(action: method, params: params, jsBridgeCallback: callback)
        } else {
            if let cls: AnyClass = NSClassFromString(appName + "." + pluginName) {
                guard let nsClass = cls as? XWidgetPlugin.Type else {
                    return
                }
                let plugin = nsClass.init()
                bridgePluginMap[pluginName] = plugin
                plugin.execute(action: method, params: params, jsBridgeCallback: callback)
            }
        }
    }
}

