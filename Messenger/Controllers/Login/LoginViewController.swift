//
//  LoginViewController.swift
//  Messenger
//
//  Created by Kadir Yildiz on 11/9/2024.
//

import UIKit
import FirebaseAuth
import FBSDKLoginKit
import JGProgressHUD


class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let fbLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        fbLoginButton.delegate = self
        
        // Add Subview
        view.addSubview(scrollView)
        
        scrollView.addSubview(emailField)
        scrollView.addSubview(imageView)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(fbLoginButton)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2, y: 20, width: size, height: size)
        emailField.frame = CGRect(x: 30, y: imageView.bottom+10, width: scrollView.width-60, height: 52)
        passwordField.frame = CGRect(x: 30, y: emailField.bottom+10, width: scrollView.width-60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordField.bottom+10, width: scrollView.width-60, height: 52)
        
        fbLoginButton.frame = CGRect(x: 30, y: loginButton.bottom+20, width: scrollView.width-60, height: 52)
        fbLoginButton.frame.origin.y = loginButton.bottom+20
    }
    
    @objc private func loginButtonTapped() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        spinner.show(in: view)

        // Firebase Log In
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }

            guard let result = authResult , error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"],
                          let lastName = userData["last_name"] else {
                        return
                    }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")

                case.failure(let error):
                    print("Faield to get data for user: \(error)")
                }
            })
            
            UserDefaults.standard.set(email, forKey: "email")


            
            print("Logged In User: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            
        })
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Alert", message: "Please enter all information to log in.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}

import FBSDKLoginKit
import FirebaseAuth

extension LoginViewController: LoginButtonDelegate {
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginKit.FBLoginButton) {
        // No operation needed on logout
    }
    
    func loginButton(_ loginButton: FBSDKLoginKit.FBLoginButton, didCompleteWith result: FBSDKLoginKit.LoginManagerLoginResult?, error: (any Error)?) {
        if let error = error {
            // Handle error on login attempt
            print("Error during Facebook login: \(error.localizedDescription)")
            return
        }
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with Facebook - No token found")
            return
        }
        guard let accessToken = AccessToken.current?.tokenString else {
            return
        }
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields": "email, name"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        
        facebookRequest.start(completion: { _, result, error in
            guard let result = result as? [String: Any], error == nil else {
                print("Failed to make facebook graph request")
                return
            }
            
            guard let userName = result["name"] as? String,
                  let email = result["email"] as? String else {
                print(error?.localizedDescription ?? "")
                return
            }
            let nameComponents = userName.components(separatedBy: " ")
            guard nameComponents.count == 2 else {
                return
            }
            let firstName = nameComponents[0]
            let lastName = nameComponents[1]
            
            DatabaseManager.shared.userExists(with: email, completion: {exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName,
                                               lastName: lastName,
                                               emailAddress: email)
                    
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            // upload image 
                        }
                    } )
                }
            })
            
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken) // Corrected spelling
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let strongSelf = self else {
                    return
                }
                
                if let error = error {
                    print("Facebook credential login failed, MFA may be needed - \(error.localizedDescription)")
                    return
                }
                
                // Successfully logged in
                print("Successfully logged user in with Facebook")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        })
    }
}
