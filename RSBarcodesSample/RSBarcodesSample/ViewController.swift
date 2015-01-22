//
//  ViewController.swift
//  RSBarcodesSample
//
//  Created by R0CKSTAR on 6/10/14.
//  Copyright (c) 2014 P.D.Q. All rights reserved.
//

import UIKit
import AVFoundation
import RSBarcodes

class ViewController: RSCodeReaderViewController {
    
    @IBOutlet var toggle: UIButton!
    
    @IBAction func close(sender: AnyObject?) {
        println("close called.")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func toggle(sender: AnyObject?) {
        session.beginConfiguration()
        device.lockForConfiguration(nil)
        
        if device.torchMode == AVCaptureTorchMode.Off {
            device.torchMode = AVCaptureTorchMode.On
        } else if device.torchMode == AVCaptureTorchMode.On {
            device.torchMode = AVCaptureTorchMode.Off
        }
        
        device.unlockForConfiguration()
        session.commitConfiguration()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        focusMarkLayer.strokeColor = UIColor.redColor().CGColor
        
        cornersLayer.strokeColor = UIColor.yellowColor().CGColor
        
        tapHandler = { point in
            println(point)
        }
        
        barcodesHandler = { [unowned self] barcodes in
            for barcode in barcodes {
                println(barcode)
                // Add logic here to find the certain barcode you are looking for
                // Store in somewhere or notify other controller to update UI
                
                let object: AVMetadataMachineReadableCodeObject = barcode
                NSUserDefaults.standardUserDefaults().setObject(object.type, forKey: "type")
                NSUserDefaults.standardUserDefaults().setObject(object.stringValue, forKey: "value")
                NSUserDefaults.standardUserDefaults().synchronize()
                
//                NSNotificationCenter.defaultCenter().postNotificationName("BarcodeDidFind", object: barcode)
                
                self.dismissViewControllerAnimated(true, completion: { () -> Void in
                    if let w = UIApplication.sharedApplication().keyWindow {
                        let n: UINavigationController = w.rootViewController as UINavigationController
                        if let s = n.storyboard {
                            let c = s.instantiateViewControllerWithIdentifier("CODE") as UIViewController
                            n.pushViewController(c, animated: true)
                        }
                    }
                })
                break
            }
        }
        
        let types = NSMutableArray(array: output.availableMetadataObjectTypes)
        output.metadataObjectTypes = NSArray(array: types)
        
        // MARK: NOTE: If you layout views in storyboard, you should these 3 lines
        for subview in self.view.subviews {
            self.view.bringSubviewToFront(subview as UIView)
        }
        
        if !device.hasTorch {
            toggle.enabled = false
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBarHidden = true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        self.navigationController?.navigationBarHidden = false
    }
}