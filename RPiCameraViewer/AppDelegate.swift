// Copyright © 2016-2017 Shawn Baker using the MIT License.
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
    // instance variables
    var window: UIWindow?
    var settings = Settings()
    var cameras = [Camera]()

    //**********************************************************************
    // application
    //**********************************************************************
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        load()
        
        let barColor = UIColor(red: 224/255, green: 0, blue: 0, alpha: 1)
        UINavigationBar.appearance().barTintColor = barColor
        UINavigationBar.appearance().tintColor = UIColor.white
		UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        UITabBar.appearance().barTintColor = barColor
        UITabBar.appearance().tintColor = UIColor.white
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
    }

    //**********************************************************************
    // applicationWillEnterForeground
    //**********************************************************************
    func applicationWillEnterForeground(_ application: UIApplication)
    {
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
        let userDefults = UserDefaults.standard
        if let data = userDefults.object(forKey: "settings") as? NSData
        {
            settings = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Settings
        }
        else
        {
            let data = NSKeyedArchiver.archivedData(withRootObject: settings);
            userDefults.set(data, forKey: "settings")
        }
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
        let userDefults = UserDefaults.standard
        var data = NSKeyedArchiver.archivedData(withRootObject: settings);
        userDefults.set(data, forKey: "settings")
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
        guard let value = intField.value else
        {
            let message = String(format: "errorNoValue".local, name)
            error(vc, message)
            return nil
        }
        guard value >= intField.min && value <= intField.max else
        {
            let message = String(format: "errorValueOutOfRange".local, name, intField.min, intField.max)
            error(vc, message)
            return nil
        }
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

