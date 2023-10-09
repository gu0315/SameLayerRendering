//
//  SameLayerDelegate.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/8/31.
//

import UIKit

@objc (SameLayerProtocol)

public protocol SameLayerDelegate: NSObjectProtocol {
    @objc func wKChildScrollViewdidMoveToWindow(childScrollView: UIView, tongcengId: String)
}
