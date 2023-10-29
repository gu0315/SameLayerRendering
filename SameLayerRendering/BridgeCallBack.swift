//
//  BridgeCallBack.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/29.
//

import UIKit
import WebKit

class BridgeCallBack: NSObject {
    
    var message: WKScriptMessage?
    
    var webview: WKWebView?
    
    static let callback = BridgeCallBack.init()
    
    func setMessage(_ message: WKScriptMessage) {
        self.message = message
        self.webview = message.webView;
    }
    
}
