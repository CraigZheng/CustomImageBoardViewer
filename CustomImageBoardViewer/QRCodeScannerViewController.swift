//
//  QRCodeScannerViewController.swift
//  CustomImageBoardViewer
//
//  Created by Craig Zheng on 2/1/18.
//  Copyright © 2018 Craig. All rights reserved.
//

import AVFoundation

class QRCodeScannerViewController: UIViewController {
  
  @IBOutlet var cameraPreviewView: UIView!
  fileprivate var captureSession: AVCaptureSession?
  fileprivate var warningAlertController: UIAlertController?
  fileprivate var capturedCookie: String?
  
  enum SegueIdentifier: String {
    case qrScanner, cookieDetail
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Request camera permission.
    AVCaptureDevice.requestAccess(for: AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.video)), completionHandler: { (granted) in
      DispatchQueue.main.async(execute: {
        if (granted) {
          // Permission has been granted. Use dispatch_async for any UI updating
          // code because this block may be executed in a thread.
          self.setUpScanner()
        } else {
          // No permission, inform user about the permission issue, or quit.
          let alertController = UIAlertController(title: "We Would Like To Use Your Camera", message: nil, preferredStyle: .alert)
          alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
            // Dismiss self.
            _ = self?.navigationController?.popToRootViewController(animated: true)
          }))
          alertController.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            let settingsUrl = URL(string: UIApplication.openSettingsURLString)
            if let url = settingsUrl {
              UIApplication.shared.openURL(url)
            }
          }))
          self.present(alertController, animated: true, completion: nil)
        }
      })
    })
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    captureSession?.stopRunning()
  }
  
  fileprivate func setUpScanner() {
    captureSession?.stopRunning()
    captureSession = AVCaptureSession()
    let videoCaptureDevice = AVCaptureDevice.default(for: AVMediaType(rawValue: convertFromAVMediaType(AVMediaType.video)))
    if let videoInput = try? AVCaptureDeviceInput(device:videoCaptureDevice),
      let captureSession = captureSession
    {
      captureSession.addInput(videoInput)
      let metadataOutput = AVCaptureMetadataOutput()
      captureSession.addOutput(metadataOutput)
      metadataOutput.setMetadataObjectsDelegate(self, queue:DispatchQueue.main)
      metadataOutput.metadataObjectTypes = [convertFromAVMetadataObjectObjectType(AVMetadataObject.ObjectType.qr), convertFromAVMetadataObjectObjectType(AVMetadataObject.ObjectType.ean13)]
      let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      previewLayer.frame = self.cameraPreviewView.bounds; // Align to cameraPreviewView.
      previewLayer.videoGravity = AVLayerVideoGravity(rawValue: convertFromAVLayerVideoGravity(AVLayerVideoGravity.resizeAspectFill));
      cameraPreviewView.layer.addSublayer(previewLayer)
      captureSession.startRunning()
    }
  }
}

// MARK: Navigation
extension QRCodeScannerViewController {
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let cookieDetailViewController = segue.destination as? CookieDetailTableViewController {
      cookieDetailViewController.cookieValue = capturedCookie
    }
  }
  
}

// MARK: UI actions.

extension QRCodeScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  @IBAction func loadFromLibraryAction(_ sender: AnyObject) {
    let picker = UIImagePickerController()
    picker.allowsEditing = false
    picker.sourceType = .photoLibrary
    picker.delegate = self
    present(picker, animated: true, completion: nil)
  }
  
  // MARK: UIImagePickerControllerDelegate
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

    if let pickedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage,
      let ciImage = CIImage(image: pickedImage)
    {
      let parsedResult = performQRCodeDetection(ciImage)
      if let last = parsedResult.last, let cookieValue = czzCookieManager.sharedInstance().cookie(from: last) {
        capturedCookie = cookieValue
      }
    }
    dismiss(animated: true) {
      if self.capturedCookie?.isEmpty == false {
        self.performSegue(withIdentifier: SegueIdentifier.cookieDetail.rawValue, sender: nil)
      }
    }
  }
}

// MARK: AVCaptureMetadataOutputObjectsDelegate
extension QRCodeScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
  
  func metadataOutput(_ captureOutput: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    if let lastMetadataObject = metadataObjects.last,
      let readableObject = lastMetadataObject as? AVMetadataMachineReadableCodeObject
    {
      if readableObject.type.rawValue == convertFromAVMetadataObjectObjectType(AVMetadataObject.ObjectType.qr),
        let cookieValue = czzCookieManager.sharedInstance().cookie(from: readableObject.stringValue),
        !cookieValue.isEmpty {
        capturedCookie = cookieValue
        captureSession?.stopRunning()
        performSegue(withIdentifier: SegueIdentifier.cookieDetail.rawValue, sender: nil)
        return
      }
    }
    if warningAlertController == nil {
      // Cannot parse.
      warningAlertController = UIAlertController(title: "QR code cannot be parsed, please try again", message: nil, preferredStyle: .alert)
      warningAlertController?.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (_) in
        self.warningAlertController = nil
      }))
      present(warningAlertController!, animated: true, completion: nil)
    }
  }
}

// MARK: Read from library
extension QRCodeScannerViewController {
  // Shamelessly copied from http://stackoverflow.com/questions/35956538/how-to-read-qr-code-from-static-image and modified to my need.
  func performQRCodeDetection(_ image: CIImage) -> [String] {
    let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh, CIDetectorAspectRatio: 1.0])
    let features = detector?.features(in: image)
    var strings = [String]()
    features?.forEach { feature in
      if let feature = feature as? CIQRCodeFeature {
        strings.append(feature.messageString!)
      }
    }
    return strings
  }
  
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVMediaType(_ input: AVMediaType) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVMetadataObjectObjectType(_ input: AVMetadataObject.ObjectType) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromAVLayerVideoGravity(_ input: AVLayerVideoGravity) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
