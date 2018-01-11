// Copyright © 2016-2018 Shawn Baker using the MIT License.
import Foundation

class Settings: NSObject, NSCoding
{
    // instance variables
    var cameraName = "camera".local
    var showAllCameras = false
	var scanTimeout = 500
	var port = 5001

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
		port = decoder.decodeInteger(forKey: "port")
    }
    
    //**********************************************************************
    // encode
    //**********************************************************************
    func encode(with encoder: NSCoder)
    {
        encoder.encode(cameraName, forKey: "cameraName")
		encoder.encode(showAllCameras, forKey: "showAllCameras")
		encoder.encode(scanTimeout, forKey: "scanTimeout")
		encoder.encode(port, forKey: "port")
    }
}
