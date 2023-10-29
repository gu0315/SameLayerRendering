//
//  HybridXSLRegisterClassProtocol.swift
//  SameLayerRendering
//  此协议暂时用不到 
//  Created by 顾钱想 on 2023/8/31.
//

import UIKit

@objc (HybridXSLRegisterClassProtocol)

public protocol HybridXSLRegisterClassProtocol: NSObjectProtocol {
    
    @objc static func elementName() -> String
    
}
