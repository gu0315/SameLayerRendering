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
        self.view.backgroundColor = .white
        self.title = path
        self.edgesForExtendedLayout = []
        initWebView()
    }
    
    func initWebView() {
        webView = XSLWebView.init(frame: self.view.bounds)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.backgroundColor = UIColor.clear.withAlphaComponent(0)
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        self.view.addSubview(webView)
        self.jsBridge = JSBridgeManager.init(webView)
        XSLManager.sharedSLManager.initSLManagerWithWebView(webView)
        self.webView.loadFileURL(Bundle.main.url(forResource: path, withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
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


