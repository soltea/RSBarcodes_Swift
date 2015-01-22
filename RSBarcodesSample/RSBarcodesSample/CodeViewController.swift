//
//  CodeViewController.swift
//  RSBarcodesSample
//
//  Created by R0CKSTAR on 15/1/22.
//  Copyright (c) 2015年 P.D.Q. All rights reserved.
//

import UIKit

class CodeViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let type = NSUserDefaults.standardUserDefaults().objectForKey("type") as String
        let value = NSUserDefaults.standardUserDefaults().objectForKey("value") as String
        self.title = type + ":" + value
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBarHidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.navigationBarHidden = true
    }
}
