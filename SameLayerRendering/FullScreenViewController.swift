//
//  FullscreenViewController.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/10/9.
//

import UIKit
import AVKit

class FullScreenViewController: UIViewController {

    

    override func viewDidLoad() {
       super.viewDidLoad()
       
       
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
      
  
    }

}


