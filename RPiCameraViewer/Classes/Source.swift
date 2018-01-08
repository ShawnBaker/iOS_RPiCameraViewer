// Copyright © 2016-2017 Shawn Baker using the MIT License.
import Foundation

class Source: NSObject, NSCoding
{
    // instance variables
    public var address = ""
    public var port = 5001
    public var width = 1280
    public var height = 720
    public var fps = 30
    public var bps = 1000000
    
    //**********************************************************************
    // init
    //**********************************************************************
    override init()
    {
    }
    
    //**********************************************************************
    // init
    //**********************************************************************
    init(_ address: String, _ port: Int, _ width: Int,
         _ height: Int, _ fps: Int, _ bps: Int)
    {
        self.address = address
        self.port = port
        self.width = width
        self.height = height
        self.fps = fps
        self.bps = bps
    }

    //**********************************************************************
    // init
    //**********************************************************************
    convenience init(address: String)
    {
        self.init(address, 5001, 1280, 720, 15, 1000000)
    }

    //**********************************************************************
    // init
    //**********************************************************************
    convenience init(address: String, port: Int)
    {
        self.init(address, port, 1280, 720, 15, 1000000)
    }

    //**********************************************************************
    // init
    //**********************************************************************
    convenience init(_ source: Source)
    {
        self.init(source.address, source.port,
                  source.width, source.height,
                  source.fps, source.bps)
    }
    
    //**********************************************************************
    // init
    //**********************************************************************
    required init(coder decoder: NSCoder)
    {
        address = decoder.decodeObject(forKey: "address") as! String
        port = decoder.decodeInteger(forKey: "port")
        width = decoder.decodeInteger(forKey: "width")
        height = decoder.decodeInteger(forKey: "height")
        fps = decoder.decodeInteger(forKey: "fps")
        bps = decoder.decodeInteger(forKey: "bps")
    }
    
    //**********************************************************************
    // encode
    //**********************************************************************
    func encode(with encoder: NSCoder)
    {
        encoder.encode(address, forKey: "address")
        encoder.encode(port, forKey: "port")
        encoder.encode(width, forKey: "width")
        encoder.encode(height, forKey: "height")
        encoder.encode(fps, forKey: "fps")
        encoder.encode(bps, forKey: "bps")
    }
}
