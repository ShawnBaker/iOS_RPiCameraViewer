// Copyright © 2016-2019 Shawn Baker using the MIT License.
import UIKit

class HelpViewController: UIViewController
{
    // outlets
	@IBOutlet weak var helpTextView: UITextView!
    
    //**********************************************************************
    // viewDidLoad
    //**********************************************************************
    override func viewDidLoad()
    {
        super.viewDidLoad()
		
        helpTextView.attributedText = "helpText".local.htmlAttr
    }
	
	//**********************************************************************
	// viewDidLayoutSubviews
	//**********************************************************************
	override func viewDidLayoutSubviews()
	{
		helpTextView.contentOffset = CGPoint.zero
		super.viewDidLayoutSubviews()
	}
}
