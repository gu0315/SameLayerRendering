//
//  JSBridge.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/9/11.
//

import UIKit
import WebKit

class JSBridgeManager: NSObject {
    
    private var bridgeWebView: WKWebView?
    
    private var _userContentController: WKUserContentController?
    
    var jdBridgePluginMap: Dictionary<String, AnyClass> = [:]
    
    let KInjectJS = ";(function(){if(window.XWebView===undefined){window.XWebView={};window.XWebView.callNative=function(module,method,params,callbackName,callbackId){window.webkit.messageHandlers.XWebView.postMessage({'plugin':module,'method':method,'params':params,'callbackName':callbackName,'callbackId':callbackId})};window.XWebView._callNative=function(jsonstring){window.webkit.messageHandlers.XWebView.postMessage(jsonstring)}}})();"
    
    public init(_ bridgeWebView: WKWebView?) {
        super.init()
        self.bridgeWebView = bridgeWebView
        self.bridgeWebView?.configuration.userContentController.removeScriptMessageHandler(forName: "XWebView")
        self.bridgeWebView?.configuration.userContentController.add(self, name: "XWebView")
        let script = WKUserScript(source: KInjectJS, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        self.bridgeWebView?.configuration.userContentController.addUserScript(script)
    }
    
    deinit {
        self.bridgeWebView?.configuration.userContentController.removeScriptMessageHandler(forName: "XWebView")
    }
}

extension JSBridgeManager: WKScriptMessageHandler {
    //  JS Call Native
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        _userContentController = userContentController
        if (Thread.isMainThread) {
            self.invokeJsMethodWithMessage(message)
        } else {
            DispatchQueue.main.async {
                self.invokeJsMethodWithMessage(message)
            }
        }
    }
    
    func invokeJsMethodWithMessage(_  message: WKScriptMessage) {
        /*{
            method = createXsl;
            params =     {
                "hybrid_xsl_id" = "";
                methodType = createXsl;
                "xsl_id" = "hybrid-image0";
            };
            plugin = XWidgetPlugin;
            callbackName = 'callbackName'
        }*/
        // print(message.body)
        guard let dict = message.body as? Dictionary<String, Any> else { return }
        let pluginName = dict["plugin"] as? String ?? ""
        let method = dict["method"] as? String ?? dict["action"] as? String ?? ""
        let params = dict["params"] as? [String: Any] ?? [:] 
        _ = dict["callbackName"] as? String ?? ""
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
        var plugin: AnyClass? = jdBridgePluginMap[pluginName]
        if plugin == nil, let cls: AnyClass = NSClassFromString(appName + "." + pluginName) {
            plugin = cls
            jdBridgePluginMap[pluginName] = cls
        }
        let callback = BridgeCallBack.callback
        callback.message = message
        guard let obj = plugin as? NSObject.Type else { return }
        guard let widgetPlugin = obj.init() as? XWidgetPlugin else { return }
        widgetPlugin.execute(action: method, params: params, jsBridgeCallback: callback)
    }
}

