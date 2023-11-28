//
//  XInputElement.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/11/28.
//

import UIKit

class XInputElement: XSLBaseElement {
    
    lazy var input: UITextField = {
        let textFied = UITextField.init()
        textFied.adjustsFontSizeToFitWidth = true
        textFied.returnKeyType = .next
        textFied.backgroundColor = .darkGray
        return textFied
    }()

    required init() {
        super.init()
        self.containerView.addSubview(input)
    }
    
    @objc override func elementConnected(_ params: [String: Any]) {
        super.elementConnected(params)
    }
    
    @objc override class func elementName() -> String {
        return "hybrid-input"
    }
    
    override class func isElementValid() -> Bool {
        return true
    }
    
    @objc override func setSize(_ size: CGSize) {
        super.setSize(size)
        self.input.frame = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
    }
    
    @objc override func setStyleString(_ style: String) {
        super.setStyleString(style)
    }
    
    @objc func xsl__text(_ args: Dictionary<String, Any>) {
        guard let text = args["newValue"] as? String else { return }
        input.text = text
    }
    
    deinit {
        print("XInputElement销毁")
    }
}
