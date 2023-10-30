//
//  YYWebViewController.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/8/28.
//

import UIKit
import WebKit
import AVFoundation


class WebViewController: UIViewController, UIScrollViewDelegate, WKNavigationDelegate, WKUIDelegate {
    
    @objc dynamic var webView: WKWebView!
    
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
        webView = WKWebView.init(frame: self.view.bounds)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.backgroundColor = UIColor.clear.withAlphaComponent(0)
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        self.view.addSubview(webView)
        self.jsBridge = JSBridgeManager.init(webView) //JDBridgeManager.bridge(for: webView)
        XSLManager.sharedSLManager.initSLManagerWithWebView(webView)
        self.webView.loadFileURL(Bundle.main.url(forResource: path, withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
    }

    deinit {
        
    }
}


