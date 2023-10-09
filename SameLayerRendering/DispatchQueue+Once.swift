//
//  DispatchQueue+Once.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/9/12.
//

import Foundation

extension DispatchQueue {

    private static var _onceTracker: [String] = []

    static func once(token: String, block: () -> Void) {
        
        objc_sync_enter(self)
        
        defer { objc_sync_exit(self) }
        
        if _onceTracker.contains(token) {
            
            return
        }
        _onceTracker.append(token)
        
        block()
    }
}
