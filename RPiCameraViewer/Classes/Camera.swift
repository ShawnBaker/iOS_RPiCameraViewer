// Copyright © 2016-2017 Shawn Baker using the MIT License.
import Foundation

class Camera: NSObject, NSCoding
{
    // instance variables
    var network = ""
    var name = ""
    var source = Source()
	//https://stackoverflow.com/questions/29525000/how-to-use-videotoolbox-to-decompress-h-264-video-stream/29525001#29525001
    
    //**********************************************************************
    // init
    //**********************************************************************
    override init()
    {
    }
    
    //**********************************************************************
    // init
    //**********************************************************************
    init(_ network: String, _ name: String, _ source: Source)
    {
        self.network = network
        self.name = name
        self.source = source
    }
    
    //**********************************************************************
    // init
    //**********************************************************************
    convenience init(name: String)
    {
        self.init("frozen", name, Source("", 5001, 1280, 720, 15, 1000000))
    }
    
    //**********************************************************************
    // init
    //**********************************************************************
    convenience init(_ camera: Camera)
    {
        self.init(camera.network, camera.name, Source(camera.source))
    }
    
    //**********************************************************************
    // init
    //**********************************************************************
    required init(coder decoder: NSCoder)
    {
        network = decoder.decodeObject(forKey: "network") as! String
        name = decoder.decodeObject(forKey: "name") as! String
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
        encoder.encode(network, forKey: "network")
        encoder.encode(name, forKey: "name")
        let data = NSKeyedArchiver.archivedData(withRootObject: source);
        encoder.encode(data, forKey: "source")
    }
}
