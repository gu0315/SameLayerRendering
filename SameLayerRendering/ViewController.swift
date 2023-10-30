//
//  ViewController.swift
//  SameLayerRendering
//
//  Created by 顾钱想 on 2023/8/28.
//

import UIKit
import WebKit

import ZFPlayer

class ViewController: UIViewController {
   
    lazy var tableVie: UITableView = {
        let tableVie = UITableView.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        tableVie.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tableVie
    }()
    
    var data = [(name: "图片", path: "img"), (name: "视频", path: "video")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "同层渲染Demo"
        self.view.addSubview(tableVie)
        tableVie.delegate = self
        tableVie.dataSource = self
        tableVie.reloadData()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = WebViewController()
        vc.path = data[indexPath.row].path
        self.navigationController?.pushViewController(vc, animated: false)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row].name
        return cell
    }
}

