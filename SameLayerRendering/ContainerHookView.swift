//
//  ContainerHookView.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/8/28.
//

import Foundation
import UIKit

public class ContainerHookView: UIView {
    // 详看 WebKit中 - (UIView *)_web_findDescendantViewAtPoint:(CGPoint)point withEvent:(UIEvent *)event {} 
    public override func conforms(to aProtocol: Protocol) -> Bool {
        if NSStringFromProtocol(aProtocol) == "WKNativelyInteractible" {
            return true
        }
        return super.conforms(to: aProtocol)
    }
}
