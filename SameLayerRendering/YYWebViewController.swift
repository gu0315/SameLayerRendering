//
//  YYWebViewController.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/8/28.
//

import UIKit
import WebKit

class YYWebViewController: UIViewController, UIScrollViewDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    
    var webView: YYWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.title = "同层渲染"
        self.edgesForExtendedLayout = []
        initWebView()
    }
    
    func initWebView() {
        let configuration = WKWebViewConfiguration.init()
        let userConfiguration = WKUserContentController.init()
        userConfiguration.add(self, name: "messageHandler")
        configuration.userContentController = userConfiguration
        webView = YYWebView.init(frame: self.view.bounds, configuration: configuration)
        webView.navigationDelegate = self
        self.view.addSubview(webView)
        self.webView.loadFileURL(Bundle.main.url(forResource: "video", withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        print("WebView decidePolicyFor")
        return .allow
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("WebView did finish didStartProvisionalNavigation")
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("WebView did finish navigationResponse", navigationResponse)
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("WebView did finish loading local file.")
        // 注入 JavaScript 监听器
        let js = """
               var observer = new MutationObserver(function(mutationsList, observer) {
                   // 通过与原生代码通信发送变化信息
                   window.webkit.messageHandlers.messageHandler.postMessage("DOM变化了");
               });
               
               observer.observe(document, { attributes: true, childList: true, subtree: true });
               """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView did finish loading local file.")
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("WebView message", message.body)
        
        if let childScrollView = webView.findWKChildScrollViewById("cid_video", rootView: self.webView) {
            let view = ContainerHookView.init(frame: childScrollView.frame)
            view.isUserInteractionEnabled = true
            let ges = UITapGestureRecognizer(target: self, action: #selector(self.test))
            view.addGestureRecognizer(ges)
            
            let lab = UILabel.init(frame: view.frame)
            lab.text = "同层渲染，我是原声组件"
            lab.textAlignment = .center
            lab.center = view.center
            view.addSubview(lab)
            childScrollView.addSubview(view)
        }
    }
    
    @objc func test() {
        print("哈哈")
    }
    
    deinit {
        let container = self.webView.configuration.userContentController
        container.removeScriptMessageHandler(forName: "messageHandler")
    }
}
