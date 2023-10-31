//
//  XSLWebView.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/31.
//

import UIKit
import WebKit
class XSLWebView: WKWebView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    deinit {
        print("XSLWebView销毁")
    }
}
