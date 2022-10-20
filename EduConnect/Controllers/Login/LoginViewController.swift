//
//  LoginViewController.swift
//  EduConnect
//
//  Created by Noah Kim on 4/30/22.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    //scroll view
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    
    //email field element
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        //left padding of 5?
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height:0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    //password field element
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done //prompt to auto log in
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        //left padding of 5?
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height:0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true //asterisk
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Log In"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        
        loginButton.addTarget(self,
                              action: #selector(loginButtonTapped),
                              for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        //add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        emailField.frame = CGRect(x:30,
                                  y:scrollView.top + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        passwordField.frame = CGRect(x:30,
                                     y:emailField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 52)
        loginButton.frame = CGRect(x:30,
                                   y:passwordField.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 52)
    }
    
    //validation for login
    @objc private func loginButtonTapped(){
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
                  alertUserLoginError()
                  return
              }
        
        //Firebase login
        
        //IMPORTANT
        /*let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let testingVC = storyBoard.instantiateViewController(withIdentifier: "testing") as! TestingViewController
        testingVC.modalPresentationStyle = .fullScreen
        self.present(testingVC, animated: true, completion: nil)*/
        
        //weak self is needed for memory leak
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: {[weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            guard let result = authResult, error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            
            //let user = result.user
        
            //important, getting data using safe email, will need this for coordinate
            let safeEmail = DatabaseManager.safeEmail(emailAddress:email)
            DatabaseManager.shared.getDataFor(path: safeEmail, completion: {result in
                switch result{
                case.success(let data):
                    guard let userData = data as? [String: Any],
                    let firstName = userData["first_name"] as? String,
                    let lastName = userData["last_name"] as? String else {
                        return
                    }
                    //store the name in the user defaults
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "currentName")
                case.failure(let error):
                    print("Failed to read data with error \(error)")
                }
            })
            
            //store the email in user defaults
            UserDefaults.standard.set(email, forKey: "email")
            
            print("Logged In user: \(email)")
            //dismiss the navigation controller
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "Woops",
                                      message: "Please enter all information to login",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    //action for the top right navigation item ("Register") button
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }

}

extension LoginViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        if(textField == emailField){
            passwordField.becomeFirstResponder()
        }
        else if(textField == passwordField){
            loginButtonTapped()
        }
        return true
    }
}
