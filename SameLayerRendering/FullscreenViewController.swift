//
//  FullscreenViewController.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/9.
//

import UIKit
import AVKit

class FullscreenViewController: UIViewController {

    let playerLayer = AVPlayerLayer()

    override func viewDidLoad() {
       super.viewDidLoad()
       
       playerLayer.frame = view.bounds
       view.layer.insertSublayer(playerLayer, at: 0)
     }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
      super.viewWillTransition(to: size, with: coordinator)
      
      playerLayer.frame = view.bounds
    }

}


