// Copyright © 2017 Shawn Baker using the MIT License.
import Foundation
import SystemConfiguration.CaptiveNetwork
import UIKit

class Utils
{
	//**********************************************************************
	// getNetworkName
	//**********************************************************************
	class func getNetworkName() -> String
	{
		var ssid = ""
		if let interfaces = CNCopySupportedInterfaces() as NSArray?
		{
			for interface in interfaces
			{
				if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary?
				{
					ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as! String
					break
				}
			}
		}
		return ssid
	}
	
	//**********************************************************************
	// getIPAddress
	//**********************************************************************
	class func getIPAddress() -> String
	{
		var address = ""
		var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
		if getifaddrs(&ifaddr) == 0
		{
			var ptr = ifaddr
			while ptr != nil
			{
				defer { ptr = ptr?.pointee.ifa_next }
				
				let interface = ptr?.pointee
				let addrFamily = interface?.ifa_addr.pointee.sa_family
				if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6)
				{
					let name: String = String(cString: (interface?.ifa_name)!)
					if name == "en0"
					{
						var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
						getnameinfo(interface?.ifa_addr, socklen_t((interface?.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
						address = String(cString: hostname)
					}
				}
			}
			freeifaddrs(ifaddr)
		}
		return address
	}

	//**********************************************************************
	// getBaseIPAddress
	//**********************************************************************
	class func getBaseIPAddress() -> String
	{
		var ipAddress = getIPAddress();
		if let i = ipAddress.range(of: ".", options: .backwards)?.lowerBound
		{
			ipAddress = String(ipAddress[...i])
		}
		return ipAddress;
	}

	//**********************************************************************
	// isValidIPAddress
	//**********************************************************************
	class func isValidIPAddress(_ address: String) -> Bool
	{
		let parts = address.split(separator: ".")
		let octets = parts.flatMap { Int($0) }
		return parts.count == 4 && octets.count == 4 && octets.filter { $0 >= 0 && $0 < 256}.count == 4
	}
	
	//**********************************************************************
	// getNetworkCameras
	//**********************************************************************
	class func getNetworkCameras(_ network: String) -> [Camera]
	{
		let app = UIApplication.shared.delegate as! AppDelegate
		var networkCameras = [Camera]()
		for camera in app.cameras
		{
			if camera.network == network
			{
				networkCameras.append(camera)
			}
		}
	
		return networkCameras;
	}

	//**********************************************************************
	// getDefaultCameraName
	//**********************************************************************
	class func getDefaultCameraName() -> String
	{
		let app = UIApplication.shared.delegate as! AppDelegate
		return app.settings.cameraName
	}

	//**********************************************************************
	// getNetworkCameras
	//**********************************************************************
	class func getMaxCameraNumber(_ cameras: [Camera]) -> Int
	{
		var max = 0
		let defaultName = getDefaultCameraName() + " ";
		for camera in cameras
		{
			if camera.name.hasPrefix(defaultName)
			{
				let index = camera.name.index(camera.name.startIndex, offsetBy: defaultName.count)
				if let num = Int(camera.name[index...]), num > max
				{
					max = num
				}
			}
		}
		return max;
	}
	
	//**********************************************************************
	// getNextCameraName
	//**********************************************************************
	class func getNextCameraName(_ cameras: [Camera]) -> String
	{
		return getDefaultCameraName() + " " + String(getMaxCameraNumber(cameras) + 1);
	}
}
