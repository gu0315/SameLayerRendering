//
//  JSBridgeCallBack.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/29.
//

import UIKit
import WebKit

class JSBridgeCallBack: NSObject {
    
    var message: WKScriptMessage?
    
    weak var webview: WKWebView?
    
    static let callback = JSBridgeCallBack.init()
    
    var onSuccess: ((Any?) -> Void)?
    
    var onSuccessProgress: ((Any?) -> Void)?
    
    var onFail: ((Any?) -> Void)?
    
    // TODO: 调用evaluateJavaScript
    func setMessage(_ message: WKScriptMessage) {
        self.message = message
        self.webview = message.webView;
        self.onSuccess = { [weak self] arg in
            guard let _ = self else { return }
        }
        self.onFail = { [weak self] error in
            guard let _ = self else { return }
        }
        self.onSuccessProgress = { [weak self] arg in
            guard let _ = self else { return }
        }
    }
}
