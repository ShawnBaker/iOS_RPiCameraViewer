// Copyright © 2016-2017 Shawn Baker using the MIT License.
import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate
{
	var camerasViewController: CamerasViewController?
	
    //**********************************************************************
    // viewDidLoad
    //**********************************************************************
    override func viewDidLoad()
    {
        super.viewDidLoad()
        delegate = self
		
		for viewController in viewControllers!
		{
			var vc = viewController
			
			if vc is UINavigationController
			{
				let navigationController = vc as! UINavigationController
				vc = navigationController.topViewController!
			}
			
			if vc is CamerasViewController
			{
				camerasViewController = (vc as! CamerasViewController)
			}
		}
    }
    
    //**********************************************************************
    // tabBarController shouldSelect
    //**********************************************************************
    func tabBarController(_ tabBarController: UITabBarController,
                            shouldSelect viewController: UIViewController) -> Bool
    {
        if let settings = selectedViewController as? SettingsViewController
        {
			let result = settings.save()
			camerasViewController?.refreshCameras()
            return result
        }
        return true
    }
}
