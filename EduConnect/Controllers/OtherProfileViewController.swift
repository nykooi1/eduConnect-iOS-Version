//
//  OtherProfileViewController.swift
//  EduConnect
//
//  Created by Noah Kim on 5/3/22.
//

import UIKit
import CoreMIDI

class OtherProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var coursesTableView: UITableView!
    
    var courses: [String] = []
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell", for: indexPath)
        
        //set the cell text to be the name
        cell.textLabel?.text = "\(courses[indexPath.row])"
        
        return cell
    }
    
    
    var otherUserSafeEmail:String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        print(otherUserSafeEmail)
        profileImage.layer.cornerRadius = profileImage.frame.size.width/2
        //get the user informaton from the safe email passed through
        getUserInformation(safeEmail: otherUserSafeEmail)
        coursesTableView.delegate = self
        coursesTableView.dataSource = self
    }
    
    //outlets to be set
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var Name: UILabel!
    @IBOutlet weak var Major: UILabel!
    @IBOutlet weak var Instagram: UILabel!
    
    //get user information for this user (given the safe email)
    private func getUserInformation(safeEmail: String){
        DatabaseManager.shared.getUserInformation(safeEmailAddress: safeEmail, completion: { [self] result in
                switch result{
                
                //call was good
                case.success(let data):
                    
                    //get the user data from the completion handldeer
                    guard let userInformation = data as? [String:Any],
                          let firstName = userInformation["first_name"] as? String,
                          let lastName = userInformation["last_name"] as? String,
                          let major = userInformation["major"] as? String,
                          let instagramUsername = userInformation["instagram_username"] as? String else {
                              return
                    }
                    
                    if(userInformation["courses"] != nil){
                        courses = userInformation["courses"] as! [String]
                        print(courses)
                    }
                    
                    //reload the table with the pulled courses
                    coursesTableView.reloadData()
                    
                    //pull out the user information and set the labels
                    Name.text = firstName + " " + lastName
                    Major.text = major
                    Instagram.text = instagramUsername
                    
                    let path = "images/\(otherUserSafeEmail)_profile_picture.png"
                    //using the path, get the image
                    StorageManager.shared.downloadURL(for: path, completion: {[weak self] result in
                        switch result {
                        case .success(let url):
                            self?.downloadImage(imageView: (self?.profileImage)!, url:url)
                        case .failure(let error):
                            print("Failed to get download url: \(error)")
                        }
                    })
                    
                //call was bad
                case.failure(let error):
                    print("Failed to read data with error \(error)")
                }
        })
    }
    
    //sends a message to the user they are viewing
    //check if there is a conversation between the current user and this user
    /*
     Loop thorugh my conversations and see if I can find his safe email address in
     one of the keys
     
     If I can, open that conversation
     
     otherwise, instantiate a new conversation
     */
    @IBAction func sendMessage(_ sender: Any) {
        
        print("Sending a message to: \(otherUserSafeEmail)")
        
        var currentEmail: String {
            (UserDefaults.standard.value(forKey:"email") as? String)!
        }
        let currentSafeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail);
        
        //set the location and handle hte completion
        DatabaseManager.shared.getConversationIds(safeEmailAddress: currentSafeEmail, completion: { [self] result in
                switch result{
                
                //call was good
                case.success(let data):
                    
                    //get the user data from the completion handldeer
                    guard let conversationIds = data as? [String] else {
                        print("ERROR: RETURNING")
                        return
                    }
                    
                    print("Conversations:")
                    print(conversationIds)
                    
                    //whether or not a new convo should be created
                    var isNewConversation = true
                    //the existing conversation id if there is one
                    var existingConversationId: String = "garbage"
                    
                    //loop through the id and check if an existing conversation exists
                    for conversationId in conversationIds{
                        print("Check if \(conversationId) contains \(otherUserSafeEmail)")
                        //if there is a conversation id that contains the safe email
                        if(conversationId.contains(otherUserSafeEmail)){
                            print("it does contain it")
                            isNewConversation = false;
                            existingConversationId = conversationId
                            break;
                        }
                    }
                    
                    print(existingConversationId)
                    
                    //create new conversation
                    if(isNewConversation){
                        //new conversation, make one and dismiss
                        print("Begin the wave message")
                        
                        //create the sender
                        let selfSender = Sender(photoURL: "", senderId: DatabaseManager.safeEmail(emailAddress: UserDefaults.standard.value(forKey: "email") as! String), displayName: "Joe Smith")
                        
                        //create the default message
                        let msg = Message(sender: selfSender, messageId: createMessageId(), sentDate: Date(), kind: .text("🖐"))
                        
                        //get the name
                        var currentName: String {
                            (UserDefaults.standard.value(forKey:"name") as? String)!
                        }
                        
                        //make the conversation (wave) - send one message
                        DatabaseManager.shared.createNewConversation(with: otherUserSafeEmail, name: Name.text ?? "User", firstMessage: msg, completion: {success in
                            if(success){
                                print("message sent")
                                //dismiss
                                navigationController?.popViewController(animated: true)
                                dismiss(animated: true, completion: nil)
                            } else {
                                print("failed to send")
                                //dismiss
                                navigationController?.popViewController(animated: true)
                                dismiss(animated: true, completion: nil)
                            }
                        })
                    }
                    //open existing conversation
                    else{
                        //there is already an existing notification
                        navigationController?.popViewController(animated: true)
                        dismiss(animated: true, completion: nil)
                        print("open existing conversation")
                    }
                
                //call was bad
                case.failure(let error):
                    print("Failed to read data with error \(error)")
                    //they have no conversations, so you can make it here too
                    
                    //new conversation, make one and dismiss
                    print("Begin the wave message")
                    
                    //create the sender
                    let selfSender = Sender(photoURL: "", senderId: DatabaseManager.safeEmail(emailAddress: UserDefaults.standard.value(forKey: "email") as! String), displayName: "Joe Smith")
                    
                    //create the default message
                    let msg = Message(sender: selfSender, messageId: createMessageId(), sentDate: Date(), kind: .text("🖐"))
                    
                    //get the name
                    var currentName: String {
                        (UserDefaults.standard.value(forKey:"name") as? String)!
                    }
                    
                    //make the conversation (wave) - send one message
                    DatabaseManager.shared.createNewConversation(with: otherUserSafeEmail, name: Name.text ?? "User", firstMessage: msg, completion: {success in
                        if(success){
                            print("message sent")
                            //dismiss
                            navigationController?.popViewController(animated: true)
                            dismiss(animated: true, completion: nil)
                        } else {
                            print("failed to send")
                            //dismiss
                            navigationController?.popViewController(animated: true)
                            dismiss(animated: true, completion: nil)
                        }
                    })
                }
        })
    }
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    //creates a msg id
    private func createMessageId() -> String{
        //date, otherUseremail,senderEmail,randomInt
        let currentUserEmail = UserDefaults.standard.value(forKey: "email") as! String
        let currentSafeUserEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newID = "\(otherUserSafeEmail)_\(currentSafeUserEmail)_\(dateString)"
        return newID
    }
    
    //download the image from the url nad set it
    func downloadImage(imageView: UIImageView, url: URL){
        URLSession.shared.dataTask(with: url, completionHandler: {data, _, error in
            guard let data = data, error == nil else {
                return
            }
            //need to review what this is for
            //used with updating the UI in a delegate method or completion controller
            //YOU MUST DO THIS - probabily will be an issue later on
            DispatchQueue.main.async{
                let image = UIImage(data:data)
                imageView.image = image
            }
        }).resume()
    }
    
    //table to display the users courses
    @IBOutlet weak var courseTable: UITableView!

}
