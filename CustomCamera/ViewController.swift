//
//  ViewController.swift
//  CustomCamera
//
//  Created by Brian Advent on 24/01/2017.
//  Copyright © 2017 Brian Advent. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    let trafficSignPredictionModel = traffic_sign_classification()
    
    let captureSession = AVCaptureSession()
    var previewLayerBlur: CALayer!
    var previewLayerNormal: CALayer!
    
    var captureDevice:AVCaptureDevice!
    
    var takePhoto = false
    
    lazy var capturedButton: UIButton = {
        let button = UIButton(type: UIButtonType.custom)
        button.setImage(UIImage(named: "capturedButton"), for: .normal)
        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.captureImage)))
        return button
    }()
    
    lazy var photoHistoryPreviewIcon: UIImageView = {
        let icon = UIImageView()
        icon.backgroundColor = .black
        icon.layer.borderWidth = 0.5
        icon.isUserInteractionEnabled = true
        icon.contentMode = .scaleAspectFill
        icon.layer.masksToBounds = true
        icon.layer.cornerRadius = 5
        icon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showCapturedHistory)))
        return icon
    }()
    
    var cropRect: CGRect?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareCamera()
        cropRect = CGRect(x: view.center.x - 75, y: view.center.y - 75, width: 150, height: 150)
        view.backgroundColor = .black
        UIApplication.shared.statusBarStyle = .lightContent
        
        view.addSubview(capturedButton)
        _ = capturedButton.constraint(top: nil, bottom: view.bottomAnchor, left: nil, right: nil, topConstant: 0, bottomConstant: 0, leftConstant: 0, rightConstant: 0)
        capturedButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(photoHistoryPreviewIcon)
        _ = photoHistoryPreviewIcon.constraint(top: nil, bottom: view.bottomAnchor, left: view.leftAnchor, right: nil, topConstant: 0, bottomConstant: -8, leftConstant: 8, rightConstant: 0)
        photoHistoryPreviewIcon.heightAnchor.constraint(equalToConstant: 50).isActive = true
        photoHistoryPreviewIcon.widthAnchor.constraint(equalToConstant: 50).isActive = true
        
        let rectLayer = CAShapeLayer()
        rectLayer.path = UIBezierPath(rect: cropRect!).cgPath
        rectLayer.lineWidth = 1
        rectLayer.fillColor = UIColor.clear.cgColor
        rectLayer.strokeColor = UIColor.yellow.cgColor
        view.layer.addSublayer(rectLayer)
        
        let topBlurLayer = CAShapeLayer()
        topBlurLayer.path = UIBezierPath(rect: CGRect(x: 0, y: 70, width: view.frame.width, height: view.frame.height / 2 - 75 - 70)).cgPath
        topBlurLayer.fillColor = UIColor.init(white: 0.7, alpha: 0.5).cgColor
        view.layer.addSublayer(topBlurLayer)
        
        let bottomBlurLayer = CAShapeLayer()
        bottomBlurLayer.path = UIBezierPath(rect: CGRect(x: 0, y: view.center.y + 75, width: view.frame.width, height: view.frame.height / 2 - 75 - 70)).cgPath
        bottomBlurLayer.fillColor = UIColor.init(white: 0.7, alpha: 0.5).cgColor
        view.layer.addSublayer(bottomBlurLayer)
        
        let leftBlurLayer = CAShapeLayer()
        leftBlurLayer.path = UIBezierPath(rect: CGRect(x: 0, y: view.center.y - 75, width: view.frame.width / 2 - 75, height: 150)).cgPath
        leftBlurLayer.fillColor = UIColor.init(white: 0.7, alpha: 0.5).cgColor
        view.layer.addSublayer(leftBlurLayer)
        
        let rightBlurLayer = CAShapeLayer()
        rightBlurLayer.path = UIBezierPath(rect: CGRect(x: view.center.x + 75, y: view.center.y - 75, width: view.frame.width / 2 - 75, height: 150)).cgPath
        rightBlurLayer.fillColor = UIColor.init(white: 0.7, alpha: 0.5).cgColor
        view.layer.addSublayer(rightBlurLayer)
        
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinToZoom)))
        
        if let imageData = UserDefaults.standard.array(forKey: "historyImage") {
            guard let data = imageData.last as? Data else { return }
            photoHistoryPreviewIcon.image = UIImage(data: data)
        } else {
            photoHistoryPreviewIcon.image = nil
            UserDefaults.standard.set([Data](), forKey: "historyImage")
            
            UserDefaults.standard.setValue([String](), forKey: "historyImageLabel")
        }
    }
    
    @objc func pinToZoom(_ sender: UIPinchGestureRecognizer) {
        guard let device = captureDevice else { return }
        
        if sender.state == .changed {
            
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            let pinchVelocityDividerFactor: CGFloat = 5.0
            
            do {
                
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                
                let desiredZoomFactor = device.videoZoomFactor + atan2(sender.velocity, pinchVelocityDividerFactor)
                device.videoZoomFactor = max(1.0, min(desiredZoomFactor, maxZoomFactor))
                
            } catch {
                print(error)
            }
        }
    }
    
    
    func prepareCamera() {
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        let availableDevices = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back).devices
        
        captureDevice = availableDevices.first
        beginSession()
        
    }
    
    func beginSession () {
        do {
            let captureDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            
            captureSession.addInput(captureDeviceInput)
            
        }catch {
            print(error.localizedDescription)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayerBlur = previewLayer
        self.view.layer.addSublayer(self.previewLayerBlur)
        self.previewLayerBlur.frame = self.view.layer.frame
        
        captureSession.startRunning()
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [((kCVPixelBufferPixelFormatTypeKey as NSString) as String):NSNumber(value:kCVPixelFormatType_32BGRA)]
        
        dataOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }
        
        captureSession.commitConfiguration()
        
        
        let queue = DispatchQueue(label: "videoQueue")
        dataOutput.setSampleBufferDelegate(self, queue: queue)
    }
    
    @objc func captureImage() {
        self.takePhoto = true

        let flashView = CAShapeLayer()
        flashView.fillColor = UIColor.black.cgColor
        let flashAnimation = CABasicAnimation(keyPath: "opacity")
        flashAnimation.fromValue = 0
        flashAnimation.toValue = 1
        flashAnimation.duration = 0.2
        view.layer.add(flashAnimation, forKey: nil)
        
    }
    
    @objc func showCapturedHistory() {
        stopCaptureSession()
        let nav = UINavigationController(rootViewController: CapturedHistoryViewController())
        present(nav, animated: true, completion: {self.stopCaptureSession()})
    }
    
    func getImageFromSampleBuffer (buffer:CMSampleBuffer) -> UIImage? {
        if let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) {
            
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let context = CIContext()
            
            let imageRect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
            
            if let image = context.createCGImage(ciImage, from: imageRect) {
                
                return UIImage(cgImage: image, scale: 1, orientation: .right)
            }
        }
        
        return nil
    }
    
    func stopCaptureSession () {
        self.captureSession.stopRunning()
        
        if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
            for input in inputs {
                self.captureSession.removeInput(input)
            }
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate{
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if takePhoto {
            takePhoto = false
            
            if let image = self.getImageFromSampleBuffer(buffer: sampleBuffer) {
                
                let historyImageRect = CGRect(x: image.size.width / 2 - 150, y: image.size.height / 2 - 150, width: 300, height: 300)
                guard let historyImage = image.crop(cropRect: historyImageRect) else { return }
                
                let predictiveImage = historyImage.resizeImage(targetSize: CGSize(width: 48, height: 48))
                
                if let pixelBufferImage = predictiveImage.pixelBuffer() {
                    guard let output = try? trafficSignPredictionModel.prediction(image: pixelBufferImage) else { return }
                    if var currentImageLabels = UserDefaults.standard.array(forKey: "historyImageLabel") {
                        currentImageLabels.append(output.classLabel)
                        UserDefaults.standard.set(currentImageLabels, forKey: "historyImageLabel")
                    }
                    print(output.classLabel)
                }
                
                
                
                if let imageData = UIImageJPEGRepresentation(predictiveImage, 1) {
                    if var currentHistoryImages = UserDefaults.standard.array(forKey: "historyImage") {
                        currentHistoryImages.append(imageData)
                        UserDefaults.standard.set(currentHistoryImages, forKey: "historyImage")
                    }
                    
                }
                
                
                DispatchQueue.main.async {
                    self.photoHistoryPreviewIcon.image = predictiveImage
                    CATransaction.begin()
                    CATransaction.setAnimationDuration(0.2)
                    CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
                    
                    let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
                    scaleAnimation.fromValue = 0
                    scaleAnimation.toValue = 1
                    
                    let alphaAnimation = CABasicAnimation(keyPath: "opacity")
                    alphaAnimation.fromValue = 0
                    alphaAnimation.toValue = 1
                    
                    self.photoHistoryPreviewIcon.layer.add(alphaAnimation, forKey: nil)
                    self.photoHistoryPreviewIcon.layer.add(scaleAnimation, forKey: nil)
                    
                    CATransaction.commit()
                    //self.present(photoVC, animated: true, completion: {
                    //    self.stopCaptureSession()
                    //})
                    
                }
            }
        }
    }
}

