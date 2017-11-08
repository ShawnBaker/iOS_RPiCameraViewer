// Copyright © 2016-2017 Shawn Baker using the MIT License.
import UIKit

class TabBarController: UITabBarController, UITabBarControllerDelegate
{
    //**********************************************************************
    // viewDidLoad
    //**********************************************************************
    override func viewDidLoad()
    {
        super.viewDidLoad()
        delegate = self
    }
    
    //**********************************************************************
    // tabBarController shouldSelect
    //**********************************************************************
    func tabBarController(_ tabBarController: UITabBarController,
                            shouldSelect viewController: UIViewController) -> Bool
    {
        if let settings = selectedViewController as? SettingsViewController
        {
            return settings.save()
        }
        return true
    }
}
