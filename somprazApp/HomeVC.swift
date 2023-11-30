import UIKit
import iOSDropDown

class HomeVC: UIViewController {
    
    @IBOutlet weak var enterDocNameTF: UITextField!
    @IBOutlet weak var placeTF: UITextField!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var orLbl: UILabel!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var selectDocName: DropDown!
    @IBOutlet weak var somprazLbl: UILabel!
    
    var docDisplayList = [String]()
    var arrDocList = [SelectDoctorModelElement]()
    var selectedDoctorID = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        addBtn.layer.cornerRadius = 30
        submitBtn.layer.cornerRadius = 30
        
        enterDocNameTF.delegate = self
        placeTF.delegate = self
        
        // Configure the DropDown to enable searching
        selectDocName.isSearchEnable = true
        
        // Prevent the keyboard from showing up when tapping on selectDocName
        selectDocName.inputView = UIView()
        
        getDoctorList()
        
        
        selectDocName.didSelect{(selectedText , index ,id) in
            print("Selected item: \(selectedText) at index: \(index)")
            self.selectedDoctorID = self.arrDocList[index].id
            // Close the dropdown when an item is selected
            self.selectDocName.hideList()
            
            self.view.endEditing(true)
        }
        
    
        let backButton2 = UIButton(type: .custom)
        backButton2.setImage(UIImage(named: "logoutBtn"), for: .normal)
        backButton2.addTarget(self, action: #selector(backButton2Tapped), for: .touchUpInside)
        backButton2.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton2)
        
        let buttonHeight: CGFloat = 30
        let bottomSpacing: CGFloat = 40
        
        // Create constraints
        backButton2.widthAnchor.constraint(equalToConstant: 30).isActive = true
        backButton2.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
        backButton2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        backButton2.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -bottomSpacing).isActive = true
        
        view.bringSubviewToFront(backButton2)
    }
    
    func getDoctorList() {
        
        guard let url = URL(string: "https://quizapi-omsn.onrender.com/api/get/get-only-name-with-id") else {
            print("QUIZ ERROR OCCURRED")
            return
        }
        
        URLSession.shared.makeRequest(url: url, expecting: SelectDoctorModel.self) { [weak self] result in
            switch result {
            case .success(let doctors):
                DispatchQueue.main.async {
                    
                    self?.docDisplayList = [String]()
                    self?.arrDocList = [SelectDoctorModelElement]()
                    self?.arrDocList = doctors
                    for i in 0..<doctors.count {
                        let docObj = doctors[i]
                        if let name = docObj.doctorName {
                            let n = "Dr. " + name
                            self?.docDisplayList.append(n)
                        }
                    }
                    self?.selectDocName.optionArray = self?.docDisplayList ?? [String]()
                }
            case .failure(let error):
                print(error)
            }
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
   
    @objc func backButton2Tapped() {
        // Check if loginVC is in the navigation stack
        let VC = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
        self.navigationController?.pushViewController(VC, animated: true)
        
    }

    
    @IBAction func addBtnTapped(_ sender: UIButton) {
        
        // Check if both text fields are filled
        if let enterDocNameText = enterDocNameTF.text, !enterDocNameText.isEmpty,
           let placeText = placeTF.text, !placeText.isEmpty {
            // Text fields are not empty, proceed to the next screen
            postDoctorData()
        } else {
            // Display an alert if either or both text fields are empty
            let alert = UIAlertController(title: "Validation Error", message: "Please fill in both text fields.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    
    }
    
    
    func postDoctorData() {
        guard let url = URL(string: "https://quizapi-omsn.onrender.com/api/user") else {
            return
        }
        
        // Prepare the data to send in the request body
        let doctorName = enterDocNameTF.text ?? ""
        let state = placeTF.text ?? ""
        
        // Create a dictionary with a single key "data"
        let bodyParameters: [String: Any] = [
            "doctorName": doctorName,
            "state": state
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: bodyParameters, options: .prettyPrinted)
            
            // Increase the timeout interval to 30 seconds
            var request = URLRequest(url: url, timeoutInterval: 60) // Increase to 60 seconds

            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error as NSError?, error.domain == NSURLErrorDomain, error.code == NSURLErrorTimedOut {
                    print("Request timed out.")
                    // Handle timeout error (e.g., show an alert to the user)
                } else if let error = error {
                    print("Error: \(error)")
                    // Handle other types of errors
                } else if let data = data {
                    // Process the response data
                    if let doctorInsert = try? JSONDecoder().decode(AddDocModel.self, from: data) {
                        DispatchQueue.main.async {
                            let selectedDoctorName = self.selectDocName.text
                            let VC = self.storyboard?.instantiateViewController(withIdentifier: "QuesOptionVC") as! QuesOptionVC
                            VC.selectedDoctorID = doctorInsert.id
                            VC.selectedDoctorName = self.enterDocNameTF.text ?? ""
                            self.navigationController?.pushViewController(VC, animated: true)
                        }
                    }
                }
            }
            task.resume()
        } catch {
            print("Error creating JSON data: \(error)")
        }
    }
    
    @IBAction func docNameDrpDownTapped(_ sender: DropDown) {
        //        if let apiUrl = URL(string: "https://quizapi-omsn.onrender.com/api/get/docter/name") {
        //            let session = URLSession.shared
        //            let task = session.dataTask(with: apiUrl) { (data, response, error) in
        //                if let error = error {
        //                    print("Error: \(error)")
        //                    // Handle the error, such as displaying an alert
        //                    return
        //                }
        //
        //                if let data = data {
        //                    do {
        //                        if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [String] {
        //                            self.dropDownValues = jsonArray
        //                            print(self.dropDownValues)
        //                        }
        //                    } catch {
        //                        print("Error parsing JSON: \(error)")
        //                    }
        //                }
        //            }
        //            task.resume()
        //        } else {
        //            print("Invalid URL")
        //        }
    }
    
    
    
    // Add an action for the Submit button
    @IBAction func submitBtnTapped(_ sender: UIButton) {
        // Check if a selection has been made in the dropdown
        if let selectedDoctorName = selectDocName.text, !selectedDoctorName.isEmpty {
            // Proceed to the next screen
            if let VC = self.storyboard?.instantiateViewController(withIdentifier: "QuesOptionVC") as? QuesOptionVC
            {
                VC.selectedDoctorID = selectedDoctorID
                VC.selectedDoctorName = selectedDoctorName
                self.navigationController?.pushViewController(VC, animated: true)
            }
        } else {
            // Display an alert if the dropdown is not selected
            let alert = UIAlertController(title: "Validation Error", message: "Please select Doctor's Name.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
}
extension HomeVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == enterDocNameTF {
            placeTF.becomeFirstResponder()  // Move focus to the placeTF
        } else if textField == placeTF {
            textField.resignFirstResponder()  // Hide the keyboard
        }
        return true
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}



