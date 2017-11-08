// Copyright © 2016-2017 Shawn Baker using the MIT License.
import UIKit

class HelpViewController: UIViewController
{
    // outlets
	@IBOutlet weak var navigationBar: UINavigationBar!
	@IBOutlet weak var helpTextView: UITextView!
    
    //**********************************************************************
    // viewDidLoad
    //**********************************************************************
    override func viewDidLoad()
    {
        super.viewDidLoad()
		
		let navigationItem = UINavigationItem()
		navigationItem.title = "appName".local
		navigationBar.items = [navigationItem]
		
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
