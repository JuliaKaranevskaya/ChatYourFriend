//
//  RegisterViewController.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 9.07.21.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {
    
    //MARK: UI elements
    private let registerPageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "registerPageView")
        view.tintColor = .systemGreen
        view.contentMode = .scaleAspectFit
        view.layer.cornerRadius = 50
        view.layer.masksToBounds = true
        view.clipsToBounds = true
        return view
    }()
    
    private let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 20
        field.layer.borderWidth = 2
        field.layer.borderColor = UIColor.systemGray.cgColor
        field.backgroundColor = .white
        field.placeholder = "Name"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        field.leftViewMode = .always
        return field
    }()
    
    private let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 20
        field.layer.borderWidth = 2
        field.layer.borderColor = UIColor.systemGray.cgColor
        field.backgroundColor = .white
        field.placeholder = "Surname"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        field.leftViewMode = .always
        return field
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 20
        field.layer.borderWidth = 2
        field.layer.borderColor = UIColor.systemGray.cgColor
        field.backgroundColor = .white
        field.placeholder = "E-mail address"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        field.leftViewMode = .always
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 20
        field.layer.borderWidth = 2
        field.layer.borderColor = UIColor.systemGray.cgColor
        field.backgroundColor = .white
        field.placeholder = "Enter your password"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        field.leftViewMode = .always
        field.isSecureTextEntry = true
        return field
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = UIColor.init(named: "darkPurple")
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(didTapRegister), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        view.backgroundColor = UIColor.init(named: "lightPurple")
        title = "Register"
        
        firstNameField.delegate = self
        lastNameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
       
        view.addSubview(registerPageView)
        view.addSubview(firstNameField)
        view.addSubview(lastNameField)
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(registerButton)
        
        registerPageView.isUserInteractionEnabled = true
        view.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeUserImage))
        registerPageView.addGestureRecognizer(gesture)
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setComponents()
    }
}

//MARK: - Firebase Registration
extension RegisterViewController {
 
    @objc private func didTapRegister() {
   
        guard let firstName = firstNameField.text,
            let lastName = lastNameField.text,
            let email = emailField.text,
            let password = passwordField.text,
            !firstName.isEmpty,
            !lastName.isEmpty,
            !email.isEmpty,
            !password.isEmpty else {
            alertRegisterError()
            return
        }
     
        DatabaseManager.shared.validateNewUser(by: email) { [weak self] oldUser in
         
            guard !oldUser else {
                self?.alertNotNewUserError()
                return
            }
        
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
                
                guard authResult != nil, error == nil else {
                    print("Register error")
                    return
                }
                
                UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                UserDefaults.standard.setValue(email, forKey: "email")
                
                let user = MessengerUser(firstName: firstName, lastName: lastName, email: email)
                
                DatabaseManager.shared.addUser(user: user) { done in
                    if done {
                        guard let image = self?.registerPageView.image,
                              let data = image.pngData() else {
                            return
                        }
                        let fileName = user.userPictureName
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: fileName) { result in
                            switch result {
                            case .success(let downloadURL):
                                UserDefaults.standard.set(downloadURL, forKey: "profile_picture_URL")
                                print("success")
                            case .failure(let error):
                                print(error)
                            }
                        }
                    }
                }
                
                self?.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
}

//MARK: - View Configuration
extension RegisterViewController {
    
    private func setComponents() {
        setRegisterPageView()
        setFirstNameField()
        selLastNameField()
        setEmailField()
        setPasswordField()
        setRegisterButton()
    }
    
    private func setRegisterPageView() {
        registerPageView.translatesAutoresizingMaskIntoConstraints = false
        registerPageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        registerPageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        registerPageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        registerPageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    private func setFirstNameField() {
        firstNameField.translatesAutoresizingMaskIntoConstraints = false
        firstNameField.topAnchor.constraint(equalTo: registerPageView.bottomAnchor, constant: 10).isActive = true
        firstNameField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        firstNameField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        firstNameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
        firstNameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50).isActive = true
    }
    
    private func selLastNameField() {
        lastNameField.translatesAutoresizingMaskIntoConstraints = false
        lastNameField.topAnchor.constraint(equalTo: firstNameField.bottomAnchor, constant: 10).isActive = true
        lastNameField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        lastNameField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        lastNameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
        lastNameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50).isActive = true
    }
    
    private func setEmailField() {
        emailField.translatesAutoresizingMaskIntoConstraints = false
        emailField.topAnchor.constraint(equalTo: lastNameField.bottomAnchor, constant: 10).isActive = true
        emailField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        emailField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
        emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50).isActive = true
    }
    
    private func setPasswordField() {
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 10).isActive = true
        passwordField.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        passwordField.heightAnchor.constraint(equalToConstant: 44).isActive = true
        passwordField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
        passwordField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50).isActive = true
    }
    
    private func setRegisterButton() {
        registerButton.translatesAutoresizingMaskIntoConstraints = false
        registerButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 10).isActive = true
        registerButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        registerButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        registerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
        registerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50).isActive = true
    }
    
}

//MARK: - Alerts
extension RegisterViewController {
    
    private func alertRegisterError() {
        let alert = UIAlertController(title: "Error", message: "Please enter all needed information", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func alertNotNewUserError() {
        let alert = UIAlertController(title: "Error", message: "The account with this email already exists.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

//MARK: - PickerController, NavigationController methods
extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @objc private func didTapChangeUserImage() {
        getUserImage()
    }
    
    func getUserImage() {
        let chooseImageSheet = UIAlertController(title: "Profile picture", message: "", preferredStyle: .actionSheet)
        
        chooseImageSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        chooseImageSheet.addAction(UIAlertAction(title: "Take a photo", style: .default, handler: { [weak self] action in
            self?.takePhoto()
            
        }))
        chooseImageSheet.addAction(UIAlertAction(title: "Choose a picture", style: .default, handler: { [weak self] action in
            self?.choosePicture()
        }))
        
        present(chooseImageSheet, animated: true)
    }
    
    func takePhoto() {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.allowsEditing = true
        controller.delegate = self
        present(controller, animated: true)
    }
    
    func choosePicture() {
        let controller = UIImagePickerController()
        controller.sourceType = .photoLibrary
        controller.allowsEditing = true
        controller.delegate = self
        present(controller, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        
        registerPageView.image = selectedImage
        picker.dismiss(animated: true, completion: nil)
    }

}

//MARK: - logic of return button on keyboard
extension RegisterViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameField {
            lastNameField.becomeFirstResponder()
        } else if textField == lastNameField {
            emailField.becomeFirstResponder()
        } else if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            didTapRegister()
        }
        return true
    }
}



