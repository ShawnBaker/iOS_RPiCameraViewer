// Copyright © 2016-2019 Shawn Baker using the MIT License.
import UIKit

class CameraViewController: InputViewController
{
    // outlets
	@IBOutlet weak var mainScrollViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var mainScrollView: UIScrollView!
	@IBOutlet weak var networkLabel: UILabel!
	@IBOutlet weak var nameTextField: UITextField!
	@IBOutlet weak var addressTextField: UITextField!
	@IBOutlet weak var portIntField: IntTextField!
	
    // instance variables
    var camera = Camera()
    
    //**********************************************************************
    // viewDidLoad
    //**********************************************************************
    override func viewDidLoad()
    {
        super.viewDidLoad()
		
		initScrollView(mainScrollView, mainScrollViewBottomConstraint)
		
		networkLabel.text = camera.network
		nameTextField.text = camera.name
		addressTextField.text = camera.address
        portIntField.value = camera.port
    }
	
    //**********************************************************************
    // textFieldShouldReturn
    //**********************************************************************
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        if textField == nameTextField || textField == addressTextField
        {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: - Navigation

    //**********************************************************************
    // shouldPerformSegue
    //**********************************************************************
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    {
        if identifier == "SaveCamera"
        {
            // error check the input values
            guard let name = nameTextField.text, name.length > 0 else
            {
                Utils.error(self, "errorNoName")
                return false
            }
            guard name == camera.name || !app.cameras.contains(where: {$0.name == name}) else
            {
                Utils.error(self, "errorNameAlreadyExists")
                return false
            }
            guard let address = addressTextField.text, address.length > 0 else
            {
                Utils.error(self, "errorNoAddress")
                return false
            }
			guard Utils.isIpAddress(address) || Utils.isHostname(address) else
			{
				Utils.error(self, "errorBadAddress")
				return false
			}
            guard let port = Utils.getIntTextField(self, portIntField, "port")
            else
            {
                return false
            }

            // assign the new values to the camera
            camera.name = name
            //camera.network = networkLabel.text!
            camera.address = address
            camera.port = port
        }
        return true
    }
}
