// Copyright © 2016-2018 Shawn Baker using the MIT License.
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
		portIntField.value = app.settings.port
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
			Utils.error(self, "errorNoName")
			return false
		}
		guard let timeout = Utils.getIntTextField(self, timeoutIntField, "scanTimeout"),
			  let port = Utils.getIntTextField(self, portIntField, "port")
		else
		{
			return false
		}
		
		// assign the new values to the settings
		app.settings.cameraName = name
		app.settings.showAllCameras = allNetworksSwitch.isOn
		app.settings.scanTimeout = timeout
		app.settings.port = port
		
		// save the settings
		app.save()
		return true
	}
}
