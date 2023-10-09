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
    
    @objc dynamic var webView: WebView!
    
    var jsBridge: JSBridge?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.title = "同层渲染"
        self.edgesForExtendedLayout = []
        initWebView()
    }
    
    func initWebView() {
        webView = WebView.init(frame: self.view.bounds)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.backgroundColor = UIColor.clear.withAlphaComponent(0)
        webView.sameLayerDelegate = self
        webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        self.view.addSubview(webView)
        self.jsBridge = JSBridge(webView: webView)
        self.webView.loadFileURL(Bundle.main.url(forResource: "video", withExtension: "html")!, allowingReadAccessTo: Bundle.main.resourceURL!)
    }
    
    // 请求之前，决定是否要跳转,点击网页上的链接，需要打开新页面时，先调用这个方法。
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
        if (navigationAction.request.url?.scheme?.contains("http") ?? false || navigationAction.request.url?.scheme?.contains("file") ?? false) {
            return .allow
        }
        return .cancel
    }
    
    // 页面开始加载时调用
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
    }
    
    // 接收到响应数据后，决定是否跳转
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    // 主机地址被重定向时调用
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
    }
    
    // 当开始加载主文档数据失败时调用
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
    }
    // 当内容开始返回时调用
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
    }
   
    // 页面加载完毕时调用
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        //WKWebview 禁止长按(超链接、图片、文本...)弹出效果
        self.webView?.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none';", completionHandler: nil)
        self.webView?.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none';", completionHandler: nil)
    }
    
    // 页面加载失败时调用
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
       
    }
    
    // 如果需要证书验证，进行验证，一般使用默认证书策略即可
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let cred = URLCredential.init(trust: challenge.protectionSpace.serverTrust!)
        completionHandler(.useCredential, cred)
    }
    
    // web内容处理中断时会触发，可针对该情况进行reload操作，可解决部分白屏问题
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        
    }
    
    deinit {
    }
}

extension WebViewController: SameLayerDelegate {
    func wKChildScrollViewdidMoveToWindow(childScrollView: UIView, tongcengId: String) {
        if childScrollView.window != nil {
            // 视图已经被添加到窗口中
            // 向H5发送attach事件，告诉H5,Native已经查找到WKChildScrollView，用于添加Native元素
            let attach = "attach('\(tongcengId)');"
            self.jsBridge?.triggerEvent(attach, completionHandler: { result, error in
                if (error == nil && (result as? Bool) == true) {
                    // 执行成功
                } else {
                    // 产生attach(添加)事件失败
                }
            })
        } else {
            // 视图已从窗口中移除
            childScrollView.subviews.forEach { subview in
                if (subview.isKind(of: ContainerHookView.self)) {
                    subview.removeFromSuperview()
                }
            }
            print("视图已从窗口中移除")
        }
    }
}
