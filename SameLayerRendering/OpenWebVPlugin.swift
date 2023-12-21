//
//  OpenWebVPlugin.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/12/19.
//

import Foundation
import UIKit

class OpenWebVPlugin: NSObject {
    
    required override init() {
        super.init()
    }
    
    func openWebViewWithUrl() {
        
    }
    
}

extension NSObject {
    // 获取最顶层的控制器
    @objc class func applicationTopVC() -> UIViewController? {
        var window: UIWindow? = UIApplication.shared.windows[0]
        if window?.windowLevel != UIWindow.Level.normal {
            let windows = UIApplication.shared.windows
            for tmpWin: UIWindow in windows {
                if tmpWin.windowLevel == UIWindow.Level.normal {
                    window = tmpWin
                    break
                }
            }
        }
        return self.topViewControllerWithRootViewController(rootViewController: window?.rootViewController)
    }
    
    static func topViewControllerWithRootViewController(rootViewController: UIViewController?) -> UIViewController? {
        if rootViewController == nil {
            assertionFailure("无根控制器")
            return nil
        }
        if let vc = rootViewController as? UITabBarController {
            if vc.viewControllers != nil {
                return topViewControllerWithRootViewController(rootViewController: vc.selectedViewController)
            } else {
                return vc
            }
        } else if let vc = rootViewController as? UINavigationController {
            if vc.viewControllers.count > 0 {
                return topViewControllerWithRootViewController(rootViewController: vc.visibleViewController)
            } else {
                return vc
            }
        } else if let vc = rootViewController as? UISplitViewController {
            if vc.viewControllers.count > 0 {
                return topViewControllerWithRootViewController(rootViewController: vc.viewControllers.last)
            } else {
                return vc
            }
        } else if let vc = rootViewController?.presentedViewController {
            return topViewControllerWithRootViewController(rootViewController: vc)
        } else {
            return rootViewController
        }
    }
}
