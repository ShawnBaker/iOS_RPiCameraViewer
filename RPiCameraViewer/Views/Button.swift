// Copyright © 2017 Shawn Baker using the MIT License.
import UIKit

@IBDesignable class Button: UIButton
{
    //**********************************************************************
    // init
    //**********************************************************************
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        self.tintColor = UIColor.white
        self.backgroundColor = Utils.primaryColor
    }
    
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
