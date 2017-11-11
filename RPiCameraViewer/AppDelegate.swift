// Copyright © 2016-2017 Shawn Baker using the MIT License.
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
    // applicationWillResignActive
    //**********************************************************************
    func applicationWillResignActive(_ application: UIApplication)
    {
        pause()
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
    // applicationDidBecomeActive
    //**********************************************************************
    func applicationDidBecomeActive(_ application: UIApplication)
    {
        resume()
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
        if let data = userDefults.object(forKey: "settings") as? NSData
        {
            settings = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Settings
        }
			
		// or create the default settings
        else
        {
            let data = NSKeyedArchiver.archivedData(withRootObject: settings);
            userDefults.set(data, forKey: "settings")
        }
		
		// get the list of cameras
        if let data = userDefults.object(forKey: "cameras") as? NSData
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
        userDefults.set(data, forKey: "settings")
		
		// save the list of cameras
        data = NSKeyedArchiver.archivedData(withRootObject: cameras);
        userDefults.set(data, forKey: "cameras")
    }
    
    //**********************************************************************
    // pause
    //**********************************************************************
    func pause()
    {
    }
    
    //**********************************************************************
    // resume
    //**********************************************************************
    func resume()
    {
    }
    
    //**********************************************************************
    // getIntTextField
    //**********************************************************************
    func getIntTextField(_ vc: UIViewController, _ intField: IntTextField, _ name: String) -> Int?
    {
		// make sure there's a value
        guard let value = intField.value else
        {
            let message = String(format: "errorNoValue".local, name)
            error(vc, message)
            return nil
        }
		
		// make sure it's in range
        guard value >= intField.min && value <= intField.max else
        {
            let message = String(format: "errorValueOutOfRange".local, name, intField.min, intField.max)
            error(vc, message)
            return nil
        }
		
		// return the value
        return value
    }
    
    //**********************************************************************
    // error
    //**********************************************************************
    func error(_ vc: UIViewController, _ message: String)
    {
        let alert = UIAlertController(title: "error".local, message: message.local, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "ok".local, style: UIAlertActionStyle.default, handler: nil))
        vc.present(alert, animated: true, completion: nil)
    }
}

