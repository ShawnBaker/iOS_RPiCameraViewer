// Copyright © 2016-2018 Shawn Baker using the MIT License.
import Foundation

class Camera: NSObject, NSCoding
{
    // instance variables
	var name = ""
    var network = ""
	var address = ""
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
    init(_ name: String, _ network: String, _ address: String, _ port: Int)
    {
        self.name = name
		self.network = network
        self.address = address
		self.port = port
    }
    
    //**********************************************************************
    // init
    //**********************************************************************
    convenience init(_ camera: Camera)
    {
        self.init(camera.name, camera.network, camera.address, camera.port)
    }
    
    //**********************************************************************
    // init
    //**********************************************************************
    required init(coder decoder: NSCoder)
    {
		name = decoder.decodeObject(forKey: "name") as! String
        network = decoder.decodeObject(forKey: "network") as! String
		address = decoder.decodeObject(forKey: "address") as! String
		port = decoder.decodeInteger(forKey: "port")
    }
    
    //**********************************************************************
    // encode
    //**********************************************************************
    func encode(with encoder: NSCoder)
    {
		encoder.encode(name, forKey: "name")
        encoder.encode(network, forKey: "network")
		encoder.encode(address, forKey: "address")
		encoder.encode(port, forKey: "port")
    }
}
