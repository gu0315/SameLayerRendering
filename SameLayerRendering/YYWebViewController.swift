//
//  YYWebViewController.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/8/28.
//

import UIKit
import WebKit

class YYWebViewController: UIViewController, UIScrollViewDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    
    @objc dynamic var webView: YYWebView!
    
    var nativeViews: Dictionary<String, UIView> = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.title = "同层渲染"
        self.edgesForExtendedLayout = []
        initWebView()
        NotificationCenter.default.addObserver(self, selector: #selector(notificationAction(notification:)), name: NSNotification.Name(rawValue: "WKChildScrollView-DidMoveToWindow"), object: nil)
    }
    
    @objc func notificationAction(notification: Notification) {
        guard let object = notification.object, let userInfo = notification.userInfo as? Dictionary<String, String> else {
            return
        }
        let str = userInfo["id"] ?? ""
        do {
            let pattern = "applets-id-.*?-end"
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            // 在字符串中搜索匹配项
            let range = NSRange(location: 0, length: str.utf16.count)
            if let match = regex.firstMatch(in: str, options: [], range: range), let view = object as? UIView {
                let matchRange = Range(match.range, in: str)!
                let matchedSubstring = str[matchRange]
                assert(!nativeViews.keys.contains(matchedSubstring.description), "存在相同的Key")
                nativeViews[matchedSubstring.description] = view
            } else {
                //
            }
        } catch {
            print("正则: \(error.localizedDescription)")
        }

        print("-----------------------------------------didMoveToWindow", object, userInfo)
    }
   
    
    func initWebView() {
        let configuration = WKWebViewConfiguration.init()
        let userConfiguration = WKUserContentController.init()
        userConfiguration.add(self, name: "messageHandler")
        configuration.userContentController = userConfiguration
        webView = YYWebView.init(frame: self.view.bounds, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
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
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("WebView did finish loading local file.")
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("WebView message", message.body)
        guard let dict = message.body as? [String: Any],
              let type = dict["type"] as? String,
              let contentId = dict["contentId"] as? String else {
            return
        }
        if let childScrollView = nativeViews[contentId] {
            if (type == "insert") {
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
        } else {
            // 没有查找到WKChildScrollView，H5同步通知Native, WebView还没有生成WKChildScrollView，可能查找查找失败，这里做一下兜底
            
        }
    }
    
    // 前端可以通过调用insertContainer向Native传递参数，插入原生组件
    @objc func insertContainer(dic: Dictionary<String, Any>) {
        
    }
    
    @objc func test() {
        print("哈哈")
    }
    
    deinit {
        let userContentController = webView.configuration.userContentController
        userContentController.removeScriptMessageHandler(forName: "messageHandler")
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("NotificationCenter.default"), object: nil)
    }
}

extension YYWebViewController: WKUIDelegate {
    private func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKContextMenuElementInfo) -> Bool {
        return false
    }
}

extension YYWebViewController: SameLayerProtocol {
    static func didMoveToWindow(view: UIView) {
        //
    }
}
