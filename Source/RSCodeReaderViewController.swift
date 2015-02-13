//
//  RSCodeReaderViewController.swift
//  RSBarcodesSample
//
//  Created by R0CKSTAR on 6/12/14.
//  Copyright (c) 2014 P.D.Q. All rights reserved.
//

import UIKit
import AVFoundation

public class RSCodeReaderViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    public lazy var device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    public lazy var output = AVCaptureMetadataOutput()
    public lazy var session = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    public lazy var focusMarkLayer = RSFocusMarkLayer()
    public lazy var cornersLayer = RSCornersLayer()
    
    public var tapHandler: ((CGPoint) -> Void)?
    public var barcodesHandler: ((Array<AVMetadataMachineReadableCodeObject>) -> Void)?
    
    public var isCrazyMode = true
    var isCrazyModeStarted = false
    var lensPosition: Float = 0
    
    var validator: NSTimer?
    
    // MARK: Private methods
    
    class func interfaceOrientationToVideoOrientation(orientation : UIInterfaceOrientation) -> AVCaptureVideoOrientation {
        var videoOrientation = AVCaptureVideoOrientation.Portrait
        switch (orientation) {
        case .PortraitUpsideDown:
            videoOrientation = AVCaptureVideoOrientation.PortraitUpsideDown
        case .LandscapeLeft:
            videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
        case .LandscapeRight:
            videoOrientation = AVCaptureVideoOrientation.LandscapeRight
        default:
            break
        }
        return videoOrientation
    }
    
    func autoUpdateLensPosition() {
        self.lensPosition += 0.01
        if self.lensPosition > 1 {
            self.lensPosition = 0
        }
        if device.lockForConfiguration(nil) {
            self.device.setFocusModeLockedWithLensPosition(self.lensPosition, completionHandler: nil)
            device.unlockForConfiguration()
        }
        if session.running {
            let when = dispatch_time(DISPATCH_TIME_NOW, Int64(10 * Double(USEC_PER_SEC)))
            dispatch_after(when, dispatch_get_main_queue(), {
                self.autoUpdateLensPosition()
            })
        }
    }
    
    func onTick() {
        self.validator!.invalidate()
        self.validator = nil
        
        self.cornersLayer.cornersArray = []
    }
    
    func onTap(gesture: UITapGestureRecognizer) {
        let tapPoint = gesture.locationInView(self.view)
        let focusPoint = CGPointMake(
            tapPoint.x / self.view.bounds.size.width,
            tapPoint.y / self.view.bounds.size.height)
        
        if self.device != nil
            && self.device.lockForConfiguration(nil) {
                if self.device.focusPointOfInterestSupported {
                    self.device.focusPointOfInterest = focusPoint
                }
                if self.isCrazyMode {
                    if self.device.isFocusModeSupported(.Locked) {
                        self.device.focusMode = .Locked
                    }
                    
                    if !self.isCrazyModeStarted {
                        self.isCrazyModeStarted = true
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.autoUpdateLensPosition()
                        })
                    }
                } else {
                    if self.device.isFocusModeSupported(.ContinuousAutoFocus) {
                        self.device.focusMode = .ContinuousAutoFocus
                    } else if self.device.isFocusModeSupported(.AutoFocus) {
                        self.device.focusMode = .AutoFocus
                    }
                }
                if self.device.autoFocusRangeRestrictionSupported {
                    self.device.autoFocusRangeRestriction = .None
                }
                self.device.unlockForConfiguration()
                self.focusMarkLayer.point = tapPoint
        }
        
        if self.tapHandler != nil {
            self.tapHandler!(tapPoint)
        }
    }
    
    func onApplicationWillEnterForeground() {
        self.session.startRunning()
    }
    
    func onApplicationDidEnterBackground() {
        self.session.stopRunning()
    }
    
    // MARK: Deinitialization
    
    deinit {
        println("RSCodeReaderViewController deinit")
    }
    
    // MARK: View lifecycle
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let videoOrientation = RSCodeReaderViewController.interfaceOrientationToVideoOrientation(UIApplication.sharedApplication().statusBarOrientation)
        if self.videoPreviewLayer != nil
            && self.videoPreviewLayer!.connection.supportsVideoOrientation
            && self.videoPreviewLayer!.connection.videoOrientation != videoOrientation {
                self.videoPreviewLayer!.connection.videoOrientation = videoOrientation
        }
    }
    
    override public func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if self.videoPreviewLayer != nil {
            self.videoPreviewLayer!.frame = CGRectMake(0, 0, size.width, size.height)
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.clearColor()
        
        var error : NSError?
        let input = AVCaptureDeviceInput(device: self.device, error: &error)
        if error != nil {
            println(error!.description)
            return
        }
        
        if self.device != nil
            && self.device.lockForConfiguration(nil) {
                if self.device.isFocusModeSupported(.ContinuousAutoFocus) {
                    self.device.focusMode = .ContinuousAutoFocus
                }
                if self.device.autoFocusRangeRestrictionSupported {
                    self.device.autoFocusRangeRestriction = .Near
                }
                self.device.unlockForConfiguration()
        }
        
        if self.session.canAddInput(input) {
            self.session.addInput(input)
        }
        
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        if self.videoPreviewLayer != nil {
            self.videoPreviewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
            self.videoPreviewLayer!.frame = self.view.bounds
            self.view.layer.addSublayer(self.videoPreviewLayer!)
        }
        
        let queue = dispatch_queue_create("com.pdq.rsbarcodes.metadata", DISPATCH_QUEUE_CONCURRENT)
        self.output.setMetadataObjectsDelegate(self, queue: queue)
        if self.session.canAddOutput(self.output) {
            self.session.addOutput(self.output)
            self.output.metadataObjectTypes = self.output.availableMetadataObjectTypes
        }
        
        let gesture = UITapGestureRecognizer(target: self, action: "onTap:")
        self.view.addGestureRecognizer(gesture)
        
        self.focusMarkLayer.frame = self.view.bounds
        self.view.layer.addSublayer(self.focusMarkLayer)
        
        self.cornersLayer.frame = self.view.bounds
        self.view.layer.addSublayer(self.cornersLayer)
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onApplicationWillEnterForeground", name:UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onApplicationDidEnterBackground", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        self.session.startRunning()
    }
    
    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        self.session.stopRunning()
    }
    
    // MARK: AVCaptureMetadataOutputObjectsDelegate
    
    public func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        var barcodeObjects : Array<AVMetadataMachineReadableCodeObject> = []
        var cornersArray : Array<[AnyObject]> = []
        for metadataObject : AnyObject in metadataObjects {
            if self.videoPreviewLayer != nil {
                let transformedMetadataObject = self.videoPreviewLayer!.transformedMetadataObjectForMetadataObject(metadataObject as AVMetadataObject)
                if transformedMetadataObject.isKindOfClass(AVMetadataMachineReadableCodeObject.self) {
                    let barcodeObject = transformedMetadataObject as AVMetadataMachineReadableCodeObject
                    barcodeObjects.append(barcodeObject)
                    cornersArray.append(barcodeObject.corners)
                }
            }
        }
        
        self.cornersLayer.cornersArray = cornersArray
        
        if barcodeObjects.count > 0 && self.barcodesHandler != nil {
            self.barcodesHandler!(barcodeObjects)
        }
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if self.validator != nil {
                self.validator!.invalidate()
                self.validator = nil
            }
            self.validator = NSTimer.scheduledTimerWithTimeInterval(0.4, target: self, selector: "onTick", userInfo: nil, repeats: true)
        })
    }
}
