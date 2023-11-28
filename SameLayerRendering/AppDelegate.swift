//
//  AppDelegate.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/8/28.
//

import UIKit
import WebKit
import ZFPlayer
import KTVHTTPCache
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    open var allowOrentitaionRotation: Bool = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        KTVHTTPCache.logSetRecordLogEnable(false)
        KTVHTTPCache.cacheSetMaxCacheLength(1024 * 1024 * 1024)
        // Override point for customization after application launch.
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        var orientationMask: ZFInterfaceOrientationMask = .portrait
        if #available(iOS 16.0, *) {
            orientationMask = ZFLandscapeRotationManager_iOS16.supportedInterfaceOrientations(for: window)

        }else if #available(iOS 15.0, *) {
            orientationMask = ZFLandscapeRotationManager_iOS15.supportedInterfaceOrientations(for: window)

        }else{
            orientationMask = ZFLandscapeRotationManager.supportedInterfaceOrientations(for: window)
        }
        
       if #available(iOS 16.0, *) {
            if allowOrentitaionRotation {
                return UIInterfaceOrientationMask.landscape
            } else {
                return UIInterfaceOrientationMask.portrait
            }
        }else {
            if orientationMask != [] {
                if orientationMask == .portrait {
                    return UIInterfaceOrientationMask.portrait
                }else if orientationMask == .landscapeLeft {
                    return UIInterfaceOrientationMask.landscapeLeft
                }else if orientationMask == .landscapeRight {
                    return UIInterfaceOrientationMask.landscapeRight
                }else if orientationMask == .landscape {
                    return UIInterfaceOrientationMask.landscape
                }else if orientationMask == .portraitUpsideDown {
                    return UIInterfaceOrientationMask.portraitUpsideDown
                }else if orientationMask == .all {
                    return UIInterfaceOrientationMask.all
                }else if orientationMask == .allButUpsideDown {
                    return UIInterfaceOrientationMask.allButUpsideDown
                }else{
                    return UIInterfaceOrientationMask.all
                }

            }else{
                return UIInterfaceOrientationMask.portrait
            }
        }
    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

