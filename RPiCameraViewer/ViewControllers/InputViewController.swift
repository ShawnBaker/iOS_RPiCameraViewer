// Copyright © 2017 Shawn Baker using the MIT License.
import UIKit

class InputViewController: UIViewController, UITextViewDelegate, UITextFieldDelegate
{
	var activeFieldRect: CGRect?
	var keyboardRect: CGRect?
	var scrollView: UIScrollView!
	var bottomConstraint: NSLayoutConstraint!
	var registered = false
	let app = UIApplication.shared.delegate as! AppDelegate

	//**********************************************************************
	// initScrollView
	//**********************************************************************
	func initScrollView(_ scrollView: UIScrollView, _ bottomConstraint: NSLayoutConstraint)
	{
		// configure the view controller
		automaticallyAdjustsScrollViewInsets = false
		
		// set the scroll view and bottom constraint
		self.scrollView = scrollView
		self.bottomConstraint = bottomConstraint
		
		// register for keyboard notifications
		registerForKeyboardNotifications()
		
		// set self as the delegate for the keyboard input fields
		for view in scrollView.subviews
		{
			if view is UITextView
			{
				let tv = view as! UITextView
				tv.delegate = self
			}
			else if view is UITextField
			{
				let tf = view as! UITextField
				tf.delegate = self
			}
		}
	}
	
	//**********************************************************************
	// viewDidLayoutSubviews
	//**********************************************************************
	override func viewDidLayoutSubviews()
	{
		super.viewDidLayoutSubviews()
		updateContentSize()
	}
	
	//**********************************************************************
	// deinit
	//**********************************************************************
	deinit
	{
		self.deregisterFromKeyboardNotifications()
	}
	
	//**********************************************************************
	// registerForKeyboardNotifications
	//**********************************************************************
	func registerForKeyboardNotifications()
	{
		if !registered
		{
			registered = true
			NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
			NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
		}
	}
	
	//**********************************************************************
	// deregisterFromKeyboardNotifications
	//**********************************************************************
	func deregisterFromKeyboardNotifications()
	{
		if registered
		{
			registered = false
			NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
			NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
		}
	}
		
	//**********************************************************************
	// keyboardWillShow
	//**********************************************************************
	@objc func keyboardWillShow(notification: NSNotification)
	{
		var info = notification.userInfo!
		keyboardRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
		adjustForKeyboard()
	}
	
	//**********************************************************************
	// keyboardWillHide
	//**********************************************************************
	@objc func keyboardWillHide(notification: NSNotification)
	{
		keyboardRect = nil
		adjustForKeyboard()
	}
	
	//**********************************************************************
	// adjustForKeyboard
	//**********************************************************************
	func adjustForKeyboard()
	{
		if scrollView != nil
		{
			if keyboardRect != nil
			{
				bottomConstraint.constant = bottomLayoutGuide.length - (keyboardRect?.height)!;
				if activeFieldRect != nil
				{
					scrollView.scrollRectToVisible(activeFieldRect!, animated: true)
				}
			}
			else
			{
				bottomConstraint.constant = 0
			}
		}
	}
	
	//**********************************************************************
	// textViewDidBeginEditing
	//**********************************************************************
	func textViewDidBeginEditing(_ textView: UITextView)
	{
		activeFieldRect = textView.frame
		adjustForKeyboard()
	}
	
	//**********************************************************************
	// textViewDidEndEditing
	//**********************************************************************
	func textViewDidEndEditing(_ textView: UITextView)
	{
		activeFieldRect = nil
		adjustForKeyboard()
	}
	
	//**********************************************************************
	// textFieldDidBeginEditing
	//**********************************************************************
	func textFieldDidBeginEditing(_ textField: UITextField)
	{
		activeFieldRect = textField.frame
		adjustForKeyboard()
	}
	
	//**********************************************************************
	// textFieldDidEndEditing
	//**********************************************************************
	func textFieldDidEndEditing(_ textField: UITextField)
	{
		activeFieldRect = nil
		adjustForKeyboard()
	}
	
	//**********************************************************************
	// updateContentSize
	//**********************************************************************
	func updateContentSize()
	{
		if scrollView != nil
		{
			let showsVerticalScrollIndicator = scrollView.showsVerticalScrollIndicator
			let showsHorizontalScrollIndicator = scrollView.showsHorizontalScrollIndicator
			
			scrollView.showsVerticalScrollIndicator = false
			scrollView.showsHorizontalScrollIndicator = false;
			
			var contentRect: CGRect = CGRect.zero
			if scrollView.subviews.count > 0
			{
				var origin = scrollView.subviews[0].frame.origin
				var max = CGPoint(x: scrollView.subviews[0].frame.maxX, y: scrollView.subviews[0].frame.maxY)
				for view in scrollView.subviews
				{
					if !view.isHidden
					{
						if view.frame.origin.x < origin.x { origin.x = view.frame.origin.x }
						if view.frame.origin.y < origin.y { origin.y = view.frame.origin.y }
						if view.frame.maxX > max.x { max.x = view.frame.maxX }
						if view.frame.maxY > max.y { max.y = view.frame.maxY }
					}
				}
				contentRect = CGRect(x: origin.x, y: origin.y, width: max.x - origin.x, height: max.y - origin.y)
			}
			
			scrollView.showsVerticalScrollIndicator = showsVerticalScrollIndicator
			scrollView.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
			
			scrollView.contentSize = CGSize(width: contentRect.width + contentRect.origin.x * 2,
											height: contentRect.height + contentRect.origin.y * 2)
		}
	}
}
