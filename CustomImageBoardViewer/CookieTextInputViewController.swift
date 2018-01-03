//
//  CookieTextInputViewController.swift
//  KomicaViewer
//
//  Created by Craig Zheng on 21/08/2016.
//  Copyright © 2016 Craig. All rights reserved.
//

import UIKit

protocol CookieTextInputViewControllerProtocol {
    func forumDetailEntered(_ inputViewController: CookieTextInputViewController, enteredDetails: String)
}

class CookieTextInputViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var insertBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    
    var allowEditing = true
    var delegate: CookieTextInputViewControllerProtocol?
    var prefilledString: String?
    var pageSpecifier: String?
  
    override func viewDidLoad() {
        super.viewDidLoad()
        if let prefilledString = prefilledString {
            textView.text = prefilledString
        }
        // Keyboard events observer.
        NotificationCenter.default.addObserver(self, selector: #selector(CookieTextInputViewController.handlekeyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CookieTextInputViewController.handleKeyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        // Configure the text view.
        insertBarButtonItem.isEnabled = pageSpecifier?.isEmpty == false
        if !allowEditing {
            textView.isEditable = false
            insertBarButtonItem.isEnabled = false
            saveBarButtonItem.isEnabled = false
        } else {
            textView.becomeFirstResponder()
        }
    }

}

extension CookieTextInputViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(_ textView: UITextView) {
        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        // When page specifier is not empty.
        if let pageSpecifier = pageSpecifier, !pageSpecifier.isEmpty {
            // Insert button enables itself when the textView.text does not contain the page specifier.
            insertBarButtonItem.isEnabled = (textView.text as NSString).range(of: pageSpecifier).location == NSNotFound
        }
    }
    
}

// MARK: UI actions.
extension CookieTextInputViewController {
    
    @IBAction func saveAction(_ sender: AnyObject) {
        textView.resignFirstResponder()
        if let enteredText = textView.text, !enteredText.isEmpty {
          // TODO: pass entered text back to the caller.
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
    
    func handlekeyboardWillShow(_ notification: Notification) {
        if let keyboardValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue
        {
            let keyboardRect = view.convert(keyboardValue.cgRectValue, from: nil)
            textViewBottomConstraint.constant = keyboardRect.size.height
            toolbarBottomConstraint.constant = keyboardRect.size.height
        }
    }
    
    func handleKeyboardWillHide(_ notification: Notification) {
        textViewBottomConstraint.constant = 0
        toolbarBottomConstraint.constant = 0
    }
    
}
