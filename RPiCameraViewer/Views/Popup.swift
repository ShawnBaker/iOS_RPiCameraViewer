// Copyright © 2017 Shawn Baker using the MIT License.
import UIKit

@IBDesignable class Popup: UIView
{
    //**********************************************************************
    // cornerRadius
    //**********************************************************************
    @IBInspectable var cornerRadius: CGFloat = 0
    {
        didSet
        {
            self.layer.cornerRadius = cornerRadius
        }
    }
}
