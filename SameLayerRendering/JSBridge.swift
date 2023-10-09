//
//  JSBridge.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/9/11.
//

import UIKit
import WebKit

class JSBridge: NSObject {
    
    public var webView: WebView?
    
    public init(webView: WebView?) {
        super.init()
        self.webView = webView
        self.webView?.configuration.userContentController.add(self, name: "bridge")
    }
    
    // Native Call Js
    func triggerEvent(_ javaScriptString: String, completionHandler: @escaping (_ result: Any?, _ error: Error?) -> Void?) {
        webView?.evaluateJavaScript(javaScriptString, completionHandler: { result, error in
            completionHandler(result, error)
        })
    }
    
    func triggerEvent(_ javaScriptString: String) {
        webView?.evaluateJavaScript(javaScriptString)
    }
    
    deinit {
        let configuration = webView?.configuration.userContentController
        configuration?.removeScriptMessageHandler(forName: "bridge")
    }
}

extension JSBridge: WKScriptMessageHandler {
    //  JS Call Native
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let parameter = message.body as? String else {
            return
        }
        let jsonData:Data = parameter.data(using: .utf8)!
        guard let dict = try? JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? Dictionary<String, Any> else {
            return
        }
        let cid = dict["cid"]
        let eventType: String = dict["eventType"] as! String
        if (eventType == "insertContainer") {
            // 插入容器
            webView?.insertContainer(containerId: cid as! String, info: dict["info"] as! [String : String])
        }
    }
}

