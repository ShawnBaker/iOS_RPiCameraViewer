// Copyright © 2017 Shawn Baker using the MIT License.
import Foundation

class NetworkInterface
{
	var name: String = ""
	var flags: UInt32 = 0
	var family: UInt8 = 0
	var address: String = ""
	var netmask: String = ""
	
	init()
	{
	}
	
	init(_ name: String, _ flags: UInt32, _ family: UInt8, _ address: String, _ netmask: String)
	{
		self.name = name
		self.flags = flags
		self.family = family
		self.address = address
		self.netmask = netmask
	}
}
