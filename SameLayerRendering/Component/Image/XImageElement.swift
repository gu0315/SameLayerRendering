//
//  XImageElement.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/26.
//

import UIKit
import SDWebImage

class XImageElement: XSLBaseElement {
    
    var src = ""
    
    lazy var imageView: UIImageView = {
        let view = UIImageView.init()
        view.contentMode = .scaleToFill
        return view
    }()

    override init() {
        super.init()
        self.containerView.addSubview(imageView)
    }
    
    @objc override func elementConnected() {
        super.elementConnected()
    }
    
    @objc override func elementRendered() {
        super.elementRendered()
    }

    @objc override class func elementName() -> String {
        return "hybrid-image"
    }
    
    override class func isElementValid() -> Bool {
        return true
    }
    
    @objc override func setSize(_ size: CGSize) {
        super.setSize(size)
        self.imageView.frame = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
    }
    
    @objc override func setStyleString(_ style: String) {
        super.setStyleString(style)
    }
    
    @objc override func setXSLStyleString(_ style: String) {
        super.setXSLStyleString(style)
    }
    
    @objc func xsl__src(_ args: Dictionary<String, Any>) {
        guard let urlString = args["newValue"] as? String else { return }
        if (self.src == urlString) { return }
        self.src = urlString
        if let imageURL = URL(string: self.src) {
            self.imageView.sd_setImage(with: imageURL)
        }
    }
}
