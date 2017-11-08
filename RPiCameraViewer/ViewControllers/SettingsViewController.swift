// Copyright © 2016-2017 Shawn Baker using the MIT License.
import UIKit

class SettingsViewController: InputViewController
{
	// outlets
	@IBOutlet weak var mainScrollViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var mainScrollView: UIScrollView!
	@IBOutlet weak var navigationBar: UINavigationBar!
	@IBOutlet weak var cameraNameTextField: UITextField!
	@IBOutlet weak var allNetworksSwitch: UISwitch!
	@IBOutlet weak var timeoutIntField: IntTextField!
	@IBOutlet weak var portIntField: IntTextField!
	@IBOutlet weak var widthIntField: IntTextField!
	@IBOutlet weak var heightIntField: IntTextField!
	@IBOutlet weak var fpsIntField: IntTextField!
	@IBOutlet weak var bpsIntField: IntTextField!

	//**********************************************************************
	// viewDidLoad
	//**********************************************************************
	override func viewDidLoad()
	{
		super.viewDidLoad()
		
		let navigationItem = UINavigationItem()
		navigationItem.title = "appName".local
		navigationBar.items = [navigationItem]
		
		initScrollView(mainScrollView, mainScrollViewBottomConstraint)
		
		cameraNameTextField.text = app.settings.cameraName
		allNetworksSwitch.isOn = app.settings.showAllCameras
		timeoutIntField.value = app.settings.scanTimeout
		portIntField.value = app.settings.source.port
		widthIntField.value = app.settings.source.width
		heightIntField.value = app.settings.source.height
		fpsIntField.value = app.settings.source.fps
		bpsIntField.value = app.settings.source.bps
	}

	//**********************************************************************
	// textFieldShouldReturn
	//**********************************************************************
	func textFieldShouldReturn(_ textField: UITextField) -> Bool
	{
		if textField == cameraNameTextField
		{
			textField.resignFirstResponder()
		}
		return true
	}

	//**********************************************************************
	// save
	//**********************************************************************
	func save() -> Bool
	{
		// error check the input values
		guard let name = cameraNameTextField.text, name.length > 0 else
		{
			app.error(self, "errorNoName")
			return false
		}
		guard let timeout = app.getIntTextField(self, timeoutIntField, "scan timeout"),
			let port = app.getIntTextField(self, portIntField, "port"),
			let width = app.getIntTextField(self, widthIntField, "width"),
			let height = app.getIntTextField(self, heightIntField, "height"),
			let fps = app.getIntTextField(self, fpsIntField, "fps"),
			let bps = app.getIntTextField(self, bpsIntField, "bps")
			else
		{
			return false
		}
		
		// assign the new values to the settings
		app.settings.cameraName = name
		app.settings.showAllCameras = allNetworksSwitch.isOn
		app.settings.scanTimeout = timeout
		app.settings.source.port = port
		app.settings.source.width = width
		app.settings.source.height = height
		app.settings.source.fps = fps
		app.settings.source.bps = bps
		
		// save the settings
		app.save()
		return true
	}
}
