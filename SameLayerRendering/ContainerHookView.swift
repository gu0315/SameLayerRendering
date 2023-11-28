//
//  ContainerHookView.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/8/28.
//

import Foundation
import UIKit

public class ContainerHookView: UIView {
    
    var viewDidRemoveWindow: () -> Void = { }
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if (self.window == nil) {
            viewDidRemoveWindow()
        }
    }
}
