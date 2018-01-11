// Copyright © 2017-2018 Shawn Baker using the MIT License.
import UIKit

class ScanningViewController: UIViewController
{
	// outlets
	@IBOutlet weak var messageLabel: UILabel!
	@IBOutlet weak var progressView: UIProgressView!
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var cancelButton: Button!
	
	// constants
	let NO_DEVICE = -1
	let NUM_THREADS = 40
	let DISMISS_TIMEOUT = 1.5
	let app = UIApplication.shared.delegate as! AppDelegate
	let semaphore = DispatchSemaphore(value: 1)
	
	// variables
	var network = Utils.getNetworkName()
	var wireless = Utils.getWirelessInterface()
	var device = 0
	var numDone = 0
	var newCameras = [Camera]()
	var scanning = true

	//**********************************************************************
	// viewDidLoad
	//**********************************************************************
    override func viewDidLoad()
    {
        super.viewDidLoad()
		
		progressView.progress = 0
		progressView.transform = progressView.transform.scaledBy(x: 1, y: 2)
		cancelButton.addTarget(self, action:#selector(handleCancelButtonTouchUpInside), for: .touchUpInside)
		if network.isEmpty || wireless.address.isEmpty
		{
			messageLabel.text = "notScanning".local
			messageLabel.textColor = Utils.badTextColor
			statusLabel.text = "errorNoNetwork".local
			statusLabel.textColor = Utils.badTextColor
			cancelButton.setTitle("done".local, for: UIControlState.normal)
		}
		else
		{
			messageLabel.text = String(format: "scanningOnPort".local, app.settings.port)
			statusLabel.text = String(format: "newCamerasFound".local, 0)
			let baseAddress = Utils.getBaseIPAddress(wireless.address)
			for _ in 1...NUM_THREADS
			{
				DispatchQueue.global(qos: .background).async
				{
					var dev = self.getNextDevice()
					while self.scanning && dev != self.NO_DEVICE
					{
						let address = baseAddress + String(dev)
						if address != self.wireless.address
						{
							let socket = openSocket(address, Int32(self.app.settings.port), Int32(self.app.settings.scanTimeout))
							if (socket >= 0)
							{
								self.addCamera(address)
								closeSocket(socket)
							}
						}
						self.doneDevice(dev)
						dev = self.getNextDevice()
					}
				}
			}
		}
    }
	
	//**********************************************************************
	// handleCancelButtonTouchUpInside
	//**********************************************************************
	@objc func handleCancelButtonTouchUpInside(_ sender: UIButton)
	{
		scanning = false
		self.performSegue(withIdentifier: "UpdateCameras", sender: self)
    }
	
	//**********************************************************************
	// getNextDevice
	//**********************************************************************
	func getNextDevice() -> Int
	{
		var nextDevice = NO_DEVICE
		semaphore.wait()
		if device < 254
		{
			device += 1
			nextDevice = device
		}
		semaphore.signal()
		return nextDevice
	}
	
	//**********************************************************************
	// doneDevice
	//**********************************************************************
	func doneDevice(_ device: Int)
	{
		semaphore.wait()
		numDone += 1
		setStatus(numDone == 254)
		semaphore.signal()
	}

	//**********************************************************************
	// addCamera
	//**********************************************************************
	func addCamera(_ address: String)
	{
		semaphore.wait()
		var found = false
		for camera in self.app.cameras
		{
			if camera.network == self.network && camera.address == address && camera.port == self.app.settings.port
			{
				found = true
				break
			}
		}
		if !found
		{
			//Log.info("addCamera: " + newCamera.source.toString())
			let camera = Camera("", self.network, address, app.settings.port)
			self.newCameras.append(camera)
		}
		semaphore.signal()
	}

	//**********************************************************************
	// addCameras
	//**********************************************************************
	func addCameras()
	{
		if newCameras.count > 0
		{
			// sort the new cameras by IP address
			//Log.info("addCameras")
			newCameras.sort(by: compareCameras)
			
			// get the maximum number from the existing camera names
			var max = Utils.getMaxCameraNumber(app.cameras)
			
			// set the camera names and add the new cameras to the list of all cameras
			let defaultName = app.settings.cameraName + " "
			for camera in newCameras
			{
				max += 1
				camera.name = defaultName + String(max)
				app.cameras.append(camera)
				//Log.info("camera: " + camera.toString())
			}
			
			app.save()
		}
	}

	//**********************************************************************
	// compareCameras
	//**********************************************************************
	func compareCameras(cam1: Camera, cam2: Camera) -> Bool
	{
		let octets1 = cam1.address.split(separator: ".")
		let octets2 = cam2.address.split(separator: ".")
		let last1 = Int(octets1[3])
		let last2 = Int(octets2[3])
		return last1! < last2!
	}
	
	//**********************************************************************
	// setStatus
	//**********************************************************************
	func setStatus(_ last: Bool)
	{
		DispatchQueue.main.async
		{
			self.progressView.progress = Float(self.numDone) / 254.0
			self.statusLabel.text = String(format: "newCamerasFound".local, self.newCameras.count)
			if self.newCameras.count > 0
			{
				self.statusLabel.textColor = Utils.goodTextColor
			}
			else if last
			{
				self.statusLabel.textColor = Utils.badTextColor
			}
			if last
			{
				self.cancelButton.setTitle("done".local, for: UIControlState.normal)
				if self.newCameras.count > 0 && self.scanning
				{
					self.addCameras()
					DispatchQueue.main.asyncAfter(deadline: .now() + self.DISMISS_TIMEOUT, execute:
					{
						self.performSegue(withIdentifier: "UpdateCameras", sender: self)
					})
				}
			}
		}
	}
}
