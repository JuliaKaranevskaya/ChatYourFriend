//
//  LoginViewController.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 9.07.21.
//

import UIKit

class LoginViewController: UIViewController {
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let loginPageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "icon")
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
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
        button.backgroundColor = .systemGreen
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        title = "Log in"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        
        emailField.delegate = self
        passwordField.delegate = self
       
        
        //Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(loginPageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
       
        
    
        

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
       
        setLoginPageView()
        setEmailField()
        setPasswordField()
        setLoginButton()
       
    }
    
    @objc private func didTapRegister() {
        let controller = RegisterViewController()
        controller.title = "Create account"
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc private func didTapLogin() {
        
        //get rid of keyboard
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        //validation
        guard let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty,
              !password.isEmpty,
              password.count >= 6 else {
            alertLoginError()
            return
        }
        
        //Firebase Log in
        
      
        
//        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
//            guard let strongSelf = self else {
//                return
//            }
//
//            DispatchQueue.main.async {
//                strongSelf.loadingSpinner.dismiss()
//            }
//
//            guard let result = authResult, error == nil else {
//                print("Log in error")
//                return
//            }
//
//            let user = result.user
//            print("\(user) logged in")
//            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
//        }
    }
    
    
    
    private func alertLoginError() {
        let alert = UIAlertController(title: "Alert", message: "Please make sure you've entered your e-mail and password. Check if password contains 6 or more symbols.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func setLoginPageView() {
        loginPageView.translatesAutoresizingMaskIntoConstraints = false
        loginPageView.topAnchor.constraint(equalTo: scrollView.safeAreaLayoutGuide.topAnchor, constant: 50).isActive = true
        loginPageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        loginPageView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        loginPageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
        

    }
    
    private func setEmailField() {
        emailField.translatesAutoresizingMaskIntoConstraints = false
        emailField.topAnchor.constraint(equalTo: loginPageView.bottomAnchor, constant: 10).isActive = true
        emailField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        emailField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        emailField.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 50).isActive = true
        emailField.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -50).isActive = true
        
    }
    
    private func setPasswordField() {
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 10).isActive = true
        passwordField.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        passwordField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        passwordField.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 50).isActive = true
        passwordField.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -50).isActive = true
    }
    
    private func setLoginButton() {
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 10).isActive = true
        loginButton.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        loginButton.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 50).isActive = true
        loginButton.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -50).isActive = true
    }
    

}

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

