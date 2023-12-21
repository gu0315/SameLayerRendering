//
//  YYWebViewController.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/8/28.
//

import UIKit
import WebKit
import AVFoundation


var XPlayer = "XPlayer"

class WebViewController: UIViewController, UIScrollViewDelegate, WKNavigationDelegate, WKUIDelegate {
    
    @objc var webView: XSLWebView!
    
    var jsBridge: JSBridgeManager?
    
    var path = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = path
        initWebView()
    }
    
    func initWebView() {
        webView = XSLWebView.init(frame: self.view.bounds)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.backgroundColor = UIColor.clear.withAlphaComponent(0)
        
        // HTML5 videos play
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        webView.configuration.allowsInlineMediaPlayback = true
        
        if #available(iOS 16.4, *) {
            webView.isInspectable = true
        } else {
            // Fallback on earlier versions
        }
        self.view.addSubview(webView)
        jsBridge = JSBridgeManager.init(webView)
        XSLManager.sharedSLManager.initSLManagerWithWebView(webView)
        self.webView.loadFileURL(Bundle.main.url(forResource: path, withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
        //self.webView.load(URLRequest.init(url: .init(string: "http://192.168.1.101:8080/")!))
    }
    
   

    deinit {
        print("WebViewController销毁")
        if #available(iOS 14.0, *) {
            self.webView.configuration.userContentController.removeAllScriptMessageHandlers()
        } else {
            // Fallback on earlier versions
        }
        self.webView.configuration.userContentController.removeAllUserScripts()
        self.webView.stopLoading()
        self.webView.uiDelegate = nil
        self.webView.navigationDelegate = nil
        self.webView.removeFromSuperview()
        self.jsBridge = nil
    }
}
