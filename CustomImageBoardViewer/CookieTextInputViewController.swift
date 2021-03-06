//
//  CookieTextInputViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

protocol CookieTextInputViewControllerDelegate {
  func textDetailEntered(_ inputViewController: CookieTextInputViewController, enteredDetails: String)
}

class CookieTextInputViewController: UIViewController {
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
  
  var allowEditing = true
  var delegate: CookieTextInputViewControllerDelegate?
  var prefilledString: String?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    if let prefilledString = prefilledString {
      textView.text = prefilledString
    }
    // Keyboard events observer.
    NotificationCenter.default.addObserver(self, selector: #selector(CookieTextInputViewController.handlekeyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(CookieTextInputViewController.handleKeyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    // Configure the text view.
    if !allowEditing {
      textView.isEditable = false
      saveBarButtonItem.isEnabled = false
    } else {
      textView.becomeFirstResponder()
    }
  }
  
}

extension CookieTextInputViewController: UITextViewDelegate {
  
  func textViewDidEndEditing(_ textView: UITextView) {
    
  }

}

// MARK: UI actions.
extension CookieTextInputViewController {
  
  @IBAction func saveAction(_ sender: AnyObject) {
    textView.resignFirstResponder()
    navigationController?.popViewController(animated: true)
    if let enteredText = textView.text, !enteredText.isEmpty {
      delegate?.textDetailEntered(self, enteredDetails: enteredText)
    }
  }
  
  @IBAction func resetAction(_ sender: AnyObject) {
    let alertController = UIAlertController(title: "", message: nil, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: {_ in
      // TODO: reset
    }))
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    alertController.popoverPresentationController?.barButtonItem = sender as? UIBarButtonItem
    present(alertController, animated: true, completion: nil)
  }
}

// MARK: keyboard events.
extension CookieTextInputViewController {
  
  @objc func handlekeyboardWillShow(_ notification: Notification) {
    if let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
    {
      let keyboardRect = view.convert(keyboardValue.cgRectValue, from: nil)
      textViewBottomConstraint.constant = keyboardRect.size.height
      toolbarBottomConstraint.constant = keyboardRect.size.height
    }
  }
  
  @objc func handleKeyboardWillHide(_ notification: Notification) {
    textViewBottomConstraint.constant = 0
    toolbarBottomConstraint.constant = 0
  }
  
}
