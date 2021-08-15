//
//  LoginViewController.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 9.07.21.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    //MARK: UI elements
    private let loginPageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "loginPageView")
        view.tintColor = .systemGreen
        view.contentMode = .scaleAspectFit
        view.layer.masksToBounds = true
        return view
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
        field.placeholder = "Enter e-mail address"
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
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log in", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.backgroundColor = UIColor.init(named: "darkPurple")
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        return button
    }()


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        
        view.backgroundColor = UIColor.init(named: "lightPurple")
        title = "Log in"
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        emailField.delegate = self
        passwordField.delegate = self
       
        view.addSubview(loginPageView)
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(loginButton)

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setComponents()
       
    }
    
    @objc private func didTapRegister() {
        let controller = RegisterViewController()
        navigationController?.pushViewController(controller, animated: true)
    }
}

//MARK: - Alerts
extension LoginViewController {
    private func alertLoginError() {
        let alert = UIAlertController(title: "Alert", message: "Please make sure you've entered your e-mail and password. Check if password contains 6 or more symbols.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

//MARK: - Firebase login
extension LoginViewController {
    @objc private func didTapLogin() {
       
        guard let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty,
              !password.isEmpty,
              password.count >= 6 else {
            alertLoginError()
            return
        }
        
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
  
            guard let result = authResult, error == nil else {
                print("Login error")
                return
            }
            
            let user = result.user
            print("\(user) logged in")
            
            let safeEmail = DatabaseManager.safeEmail(email: email)
            
            DatabaseManager.shared.getDataFor(path: safeEmail) { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                    let firstName = userData["first_name"] as? String,
                        let lastName = userData["last_name"] as? String else {
                        return
                    }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("Data error \(error)")
                }
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            
            self?.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
}


//MARK: - View Configuration
extension LoginViewController {
    
    private func setComponents() {
        setLoginPageView()
        setEmailField()
        setPasswordField()
        setLoginButton()
    }
    
    private func setLoginPageView() {
        loginPageView.translatesAutoresizingMaskIntoConstraints = false
        loginPageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        loginPageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginPageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        loginPageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
    }
    
    private func setEmailField() {
        emailField.translatesAutoresizingMaskIntoConstraints = false
        emailField.topAnchor.constraint(equalTo: loginPageView.bottomAnchor, constant: 10).isActive = true
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
    
    private func setLoginButton() {
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 10).isActive = true
        loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50).isActive = true
        loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50).isActive = true
    }
}


//MARK: - logic for return button on keyboard
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            didTapLogin()
        }
        return true
    }
}



