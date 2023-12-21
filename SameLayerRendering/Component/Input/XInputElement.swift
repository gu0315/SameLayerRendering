//
//  XInputElement.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/11/28.
//

import UIKit

class XInputElement: XSLBaseElement, UITextFieldDelegate {
    
    lazy var input: UITextField = {
        let textFied = UITextField.init()
        textFied.adjustsFontSizeToFitWidth = true
        // 下一项
        textFied.returnKeyType = .done
        textFied.backgroundColor = .darkGray
        textFied.addTarget(self, action: #selector(onChange(_ :)), for: UIControl.Event.editingChanged)
        textFied.delegate = self
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
    
    @objc func inputEditingDidEnd() {
        self.input.resignFirstResponder()
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
    
    @objc func onChange(_ sender: UITextField) {
        guard sender.text != nil else {
            return
        }
        if sender.markedTextRange == nil {
            if let bindHandle = attributes["bindonchange"] {
                let methodName = "\(bindHandle)('\(sender.text?.description ?? "")');"
                self.webView!.evaluateJavaScript(methodName) { (result, error) in
                    if let error = error {
                        print("JavaScript execution error: \(error.localizedDescription)")
                    } else {
                        print("JavaScript execution successful")
                    }
                }
            }
        }
    }
    
    // UITextFieldDelegate方法
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // 关闭键盘
        textField.resignFirstResponder()
        return true
    }
    
    deinit {
        print("XInputElement销毁")
    }
}

