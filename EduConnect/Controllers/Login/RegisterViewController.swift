//
//  RegisterViewController.swift
//  EduConnect
//
//  Created by Noah Kim on 4/30/22.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {

    //scroll view
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
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
    
    //first name
    private let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First Name"
        //left padding of 5?
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height:0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    //last name
    private let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Last Name"
        //left padding of 5?
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height:0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let majorField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Major"
        //left padding of 5?
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height:0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    //add courses later
    //add club list later
    
    //instagram username
    private let instagramUsernameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Instagram Username"
        //left padding of 5?
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height:0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .green
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
        
        registerButton.addTarget(self,
                              action: #selector(registerButtonTapped),
                              for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        //add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(majorField)
        scrollView.addSubview(instagramUsernameField)
        scrollView.addSubview(registerButton)
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapChangeProfilePic))
        gesture.numberOfTouchesRequired = 1
        imageView.addGestureRecognizer(gesture)
    }
    
    //change profile pic on click of the image
    @objc private func didTapChangeProfilePic(){
        presentPhotoActionSheet()
        print("Change pic called")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        imageView.frame = CGRect(x: (scrollView.width - size)/2, y:20, width: size, height: size)
        imageView.layer.cornerRadius = imageView.width / 2.0
        emailField.frame = CGRect(x:30,
                                  y:imageView.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 40)
        passwordField.frame = CGRect(x:30,
                                     y:emailField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 40)
        firstNameField.frame = CGRect(x:30,
                                     y:passwordField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 40)
        lastNameField.frame = CGRect(x:30,
                                     y:firstNameField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 40)
        majorField.frame = CGRect(x:30,
                                     y:lastNameField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 40)
        instagramUsernameField.frame = CGRect(x:30,
                                     y:majorField.bottom + 10,
                                     width: scrollView.width - 60,
                                     height: 40)
        registerButton.frame = CGRect(x:30,
                                   y:instagramUsernameField.bottom + 10,
                                   width: scrollView.width - 60,
                                   height: 40)
    }
    
    //validation for login
    //when registering i need to reset the UserDefaults wtfff
    @objc private func registerButtonTapped(){
        guard let firstName = firstNameField.text,
              let lastName = lastNameField.text,
              let email = emailField.text,
              let password = passwordField.text,
              let major = majorField.text,
              let instagramUsername = instagramUsernameField.text,
              !firstName.isEmpty,
              !lastName.isEmpty,
              !email.isEmpty,
              !password.isEmpty,
              !major.isEmpty,
              !instagramUsername.isEmpty,
              password.count >= 6 else {
                  alertUserRegisterError()
                  return
              }
        
        //Firebase login
        
        //check if the user exists already using completion
        DatabaseManager.shared.userExists(with: email, completion: {[weak self] exists in
            
            guard !exists else {
                //user already exists
                self?.alertUserRegisterError(message: "Looks like a user with that email already exists")
                return
            }
            
            //otherwise create the user
            
            //weak self is needed for memory leak
            FirebaseAuth.Auth.auth().createUser(withEmail: email,
                                                password: password,
                                                completion:{[weak self] authResult, error in
                guard let strongSelf = self else {
                    return
                }
                
                guard let result = authResult, error == nil else{
                    print("Error creating user")
                    return
                }
                
                //after creating the user, the object is returned in the result
                let user = result.user
                print("Created User : \(user)")
                
                //construct the user object
                let eduConnectUser = EduConnectUser(firstName: firstName,
                                                   lastName: lastName,
                                                   emailAddress: email,
                                                   instagramUsername:instagramUsername,
                                                   major: major,
                                                   xCoordinate: -1,
                                                   yCoordinate: -1,
                                                   courseList: [],
                                                   clubList: [])
                //write the user to the DB
                DatabaseManager.shared.insertUser(with: eduConnectUser, completion: { success in
                    if success {
                        //store the user on the phone defaults after they register
                        UserDefaults.standard.set(email, forKey: "email")
                        UserDefaults.standard.set("\(eduConnectUser.firstName) \(eduConnectUser.lastName)", forKey: "name")
                        //upload image
                        guard let image = strongSelf.imageView.image, let data = image.pngData() else {
                            return
                        }
                        let filename = eduConnectUser.profilePictureFileName
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: filename, completion: {result in
                            switch result{
                            case .success(let downloadURL):
                                UserDefaults.standard.set(downloadURL, forKey:"profile_picture_url")
                                print(downloadURL)
                            case .failure(let error):
                                print("Storage manager error: \(error)")
                            }
                        })
                    }
                })
                
                //dismiss the navigation controller
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
            
        })
    }
    
    //enter all information no cusotm message
    func alertUserRegisterError(){
        let alert = UIAlertController(title: "Woops",
                                      message: "Please enter all information to create a new account",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler: nil))
        present(alert, animated: true)
    }
    
    //custom message
    func alertUserRegisterError(message: String){
        let alert = UIAlertController(title: "Woops",
                                      message: message,
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

extension RegisterViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
        if(textField == emailField){
            passwordField.becomeFirstResponder()
        }
        else if(textField == passwordField){
            registerButtonTapped()
        }
        return true
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    //opens the action sheet (bottom pop up with possible selections)
    func presentPhotoActionSheet(){
        let actionSheet = UIAlertController(title: "Profile Picture", message: "How would you like to select a picture?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: {[weak self] _ in
            self?.presentCamera()
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo",
                                            style: .default,
                                            handler: {[weak self] _ in
            self?.presentPhotoPicker()
        }))
        present(actionSheet, animated: true)
    }
    
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true //cropped out square
        present(vc, animated: true) //presents the controller
    }
    
    func presentPhotoPicker(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true //cropped out square
        present(vc, animated: true) //presents the controller
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        print(info)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else{
            return
        }
        self.imageView.image = selectedImage //sets the image of the imageView created earlier
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    
}
