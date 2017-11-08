// Copyright © 2016-2017 Shawn Baker using the MIT License.
import Foundation
import UIKit

@IBDesignable
class IntTextField: UITextField, UITextFieldDelegate
{
    // instance variables
    @IBInspectable public var maxLen: Int = 10
    @IBInspectable public var min: Int = Int.min
    @IBInspectable public var max: Int = Int.max

    //**********************************************************************
    // init
    //**********************************************************************
    required init?(coder decoder: NSCoder)
    {
        super.init(coder: decoder)
        initialize()
    }
    
    //**********************************************************************
    // init
    //**********************************************************************
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        initialize()
    }
    
    //**********************************************************************
    // initialize
    //**********************************************************************
    func initialize()
    {
        delegate = self
        let toolbar: UIToolbar = UIToolbar()
        toolbar.items =
        [
            UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: self, action: nil),
            UIBarButtonItem(title: "done".local, style: UIBarButtonItemStyle.done, target: self, action: #selector(UITextField.resignFirstResponder))
        ]
        toolbar.sizeToFit()
        inputAccessoryView = toolbar
    }
    
    //**********************************************************************
    // textField shouldChangeCharactersIn
    //**********************************************************************
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool
    {
        if string.count == 0
        {
            return true
        }

        let text = textField.text ?? ""
        let newText = (text as NSString).replacingCharacters(in: range, with: string)

        let pattern = "^" + ((min < 0) ? "(\\+|-)" : "") + "\\d+$"
        let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        if regex.firstMatch(in: newText, options: [], range: NSRange(location: 0, length: newText.count)) == nil
        {
            return false
        }
        
        return newText.count <= maxLen
    }
    
    //**********************************************************************
    // value
    //**********************************************************************
    var value: Int?
    {
        get
        {
            let s = text ?? ""
            if s.count > 0,
                let n = Int(s)
                //n >= min && n <= max
            {
                return n
            }
            return nil
        }
        set
        {
            if let n = newValue
            {
                text = String(n)
            }
        }
    }
}
