// Copyright © 2016-2017 Shawn Baker using the MIT License.
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
    @IBOutlet weak var widthIntField: IntTextField!
    @IBOutlet weak var heightIntField: IntTextField!
    @IBOutlet weak var fpsIntField: IntTextField!
    @IBOutlet weak var bpsIntField: IntTextField!
	
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
		addressTextField.text = camera.source.address
        portIntField.value = camera.source.port
        widthIntField.value = camera.source.width
        heightIntField.value = camera.source.height
        fpsIntField.value = camera.source.fps
        bpsIntField.value = camera.source.bps
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
                app.error(self, "errorNoName")
                return false
            }
            guard name == camera.name || !app.cameras.contains(where: {$0.name == name}) else
            {
                app.error(self, "errorNameAlreadyExists")
                return false
            }
            guard let address = addressTextField.text, address.length > 0 else
            {
                app.error(self, "errorNoAddress")
                return false
            }
			guard Utils.isValidIPAddress(address) else
			{
				app.error(self, "errorBadAddress")
				return false
			}
            guard let port = app.getIntTextField(self, portIntField, "port"),
                let width = app.getIntTextField(self, widthIntField, "width"),
                let height = app.getIntTextField(self, heightIntField, "height"),
                let fps = app.getIntTextField(self, fpsIntField, "fps"),
                let bps = app.getIntTextField(self, bpsIntField, "bps")
            else
            {
                return false
            }

            // assign the new values to the camera
            camera.name = name
            //camera.network = networkLabel.text!
            camera.source.address = address
            camera.source.port = port
            camera.source.width = width
            camera.source.height = height
            camera.source.fps = fps
            camera.source.bps = bps
        }
        return true
    }
}
