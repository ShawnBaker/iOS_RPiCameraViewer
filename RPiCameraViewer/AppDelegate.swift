// Copyright © 2016-2018 Shawn Baker using the MIT License.
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    // instance variables
    var window: UIWindow?
    var settings = Settings()
    var cameras = [Camera]()
	var videoViewController: VideoViewController?

    //**********************************************************************
    // application
    //**********************************************************************
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
		// load the settings and cameras
        load()
		
		// set the UI element colors
        let barColor = Utils.primaryColor
        UINavigationBar.appearance().barTintColor = barColor
        UINavigationBar.appearance().tintColor = UIColor.white
		UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        UITabBar.appearance().barTintColor = barColor
        UITabBar.appearance().tintColor = UIColor.white
		UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.black], for: UIControlState.normal)
		UITabBarItem.appearance().setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: UIControlState.selected)
        UITableViewCell.appearance().tintColor = barColor
        
        return true
    }

    //**********************************************************************
    // applicationDidEnterBackground
    //**********************************************************************
    func applicationDidEnterBackground(_ application: UIApplication)
    {
        save()
		videoViewController?.stop()
    }

    //**********************************************************************
    // applicationWillEnterForeground
    //**********************************************************************
    func applicationWillEnterForeground(_ application: UIApplication)
    {
		videoViewController?.start()
    }

    //**********************************************************************
    // applicationWillTerminate
    //**********************************************************************
    func applicationWillTerminate(_ application: UIApplication)
    {
        save()
    }

    //**********************************************************************
    // load
    //**********************************************************************
    func load()
    {
		// get the settings
        let userDefults = UserDefaults.standard
        if let data = userDefults.object(forKey: "settings2") as? NSData
        {
            settings = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Settings
        }
			
		// or create the default settings
        else
        {
            let data = NSKeyedArchiver.archivedData(withRootObject: settings);
            userDefults.set(data, forKey: "settings2")
        }
		
		// get the list of cameras
        if let data = userDefults.object(forKey: "cameras2") as? NSData
        {
            cameras = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! [Camera]
        }
    }
    
    //**********************************************************************
    // save
    //**********************************************************************
    func save()
    {
		// save the settings
        let userDefults = UserDefaults.standard
        var data = NSKeyedArchiver.archivedData(withRootObject: settings);
        userDefults.set(data, forKey: "settings2")
		
		// save the list of cameras
        data = NSKeyedArchiver.archivedData(withRootObject: cameras);
        userDefults.set(data, forKey: "cameras2")
    }
}

