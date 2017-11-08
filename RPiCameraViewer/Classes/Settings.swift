// Copyright © 2016-2017 Shawn Baker using the MIT License.
import Foundation

class Settings: NSObject, NSCoding
{
    // instance variables
    var cameraName = "camera".local
    var showAllCameras = false
	var scanTimeout = 500
    var source = Source()
    
    //**********************************************************************
    // init
    //**********************************************************************
    override init()
    {
    }
    
    //**********************************************************************
    // init
    //**********************************************************************
    required init(coder decoder: NSCoder)
    {
        cameraName = decoder.decodeObject(forKey: "cameraName") as! String
        showAllCameras = decoder.decodeBool(forKey: "showAllCameras")
		scanTimeout = decoder.decodeInteger(forKey: "scanTimeout")
        if let data =  decoder.decodeObject(forKey: "source") as? NSData
        {
            source = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as! Source
        }
    }
    
    //**********************************************************************
    // encode
    //**********************************************************************
    func encode(with encoder: NSCoder)
    {
        encoder.encode(cameraName, forKey: "cameraName")
		encoder.encode(showAllCameras, forKey: "showAllCameras")
		encoder.encode(scanTimeout, forKey: "scanTimeout")
        let data = NSKeyedArchiver.archivedData(withRootObject: source);
        encoder.encode(data, forKey: "source")
    }
}
