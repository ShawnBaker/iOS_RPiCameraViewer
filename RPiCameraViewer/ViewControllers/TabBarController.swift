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
		
		// get the view controllers we want to easily access
		for viewController in viewControllers!
		{
			// set the tab bar item icon colors
			var vc = viewController
			if let image = vc.tabBarItem.image
			{
				vc.tabBarItem.image = image.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
			}
			
			// get the top view controller if necessary
			if let nav = vc as? UINavigationController
			{
				vc = nav.topViewController!
			}
			
			// get the cameras view controller
			if let cameras = vc as? CamerasViewController
			{
				camerasViewController = cameras
			}
		}
    }
    
    //**********************************************************************
    // tabBarController shouldSelect
    //**********************************************************************
    func tabBarController(_ tabBarController: UITabBarController,
                            shouldSelect viewController: UIViewController) -> Bool
    {
		if let navController = selectedViewController as? UINavigationController
		{
			if let settingsController = navController.topViewController as? SettingsViewController
			{
				let result = settingsController.save()
				camerasViewController?.refreshCameras()
				return result
			}
		}
        return true
    }
}
