//
//  ContainerHookView.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/8/28.
//

import Foundation
import UIKit

public class ContainerHookView: UIView {
    
    var nativeElementInteractionEnabled = false
    
    var viewDidRemoveWindow: () -> Void = { }
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if (self.window == nil) {
            viewDidRemoveWindow()
        }
    }
    
    public override func conforms(to aProtocol: Protocol) -> Bool {
        if #available(iOS 17, *) {
            return super.conforms(to: aProtocol)
        } else {
            if NSStringFromProtocol(aProtocol) == "WKNativelyInteractible" {
                return nativeElementInteractionEnabled
            }
            return super.conforms(to: aProtocol)
        }
    }
}
