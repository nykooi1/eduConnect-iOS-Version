//
//  ViewController.swift
//  EduConnect
//
//  Created by Noah Kim on 4/30/22.
//

//this is initially loaded in the application

import UIKit
import FirebaseAuth

//object for conversation
struct Conversation{
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}


//object for the latest message
struct LatestMessage{
    let date: String
    let text: String
    let isRead: Bool
}

class ConversationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    //store the conversations
    private var conversations = [Conversation]()
    
    //init table
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //on selection of the row, open the chat for the selected user
        let model = conversations[indexPath.row]
        let vc = ChatViewController(with: model.otherUserEmail, id: model.id) //this will be instantiated with a user !!! IMPORTANT FUTURE IMPLEMENTATION, can also copy for maps, probs pushing data through segue
        vc.title = model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    //construct table view programatically
    //a conversation list is simply a table view
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    //construct a no conversations label programatically
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
 
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView) //add the table view
        view.addSubview(noConversationsLabel) //add the no convo label
        setupTableView()
    }
    
    //update the table view
    private func startListeningForConversations(){
        
        if(UserDefaults.standard.value(forKey:"email") == nil){
            return
        }
        
        //force email to be loaded from the user defaults (DO THIS EVERYWHERE > FIXES MY ISSUE)
        var currentEmail: String {
            (UserDefaults.standard.value(forKey:"email") as? String)!
        }
        
        let currentEmailSafe = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        print("DEBUG: STARTING CONVERSATION FETCH")
        
        //gets all the conversations for a user
        //when something changes, on completion, reload the table view data
        DatabaseManager.shared.getAllConversations(for: currentEmailSafe, completion: {[weak self] result in
            switch result{
            case .success(let conversations):
                
                print("DEBUG: SUCCESSFULLY GOT CONVERSATIONS")
                
                guard !conversations.isEmpty else{
                    return
                }
                
                self?.conversations = conversations
                
                //reload the table view data
                DispatchQueue.main.async{
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("failed to get conversations: \(error)")
            }
        })
    }
    
    //compose a new message to someone
    //going to need to move this to a profile page - pay attention to what I am passing in
    @objc private func didTapComposeButton(){
        let vc = NewConversationViewController()
        vc.completion = {[weak self] result in
            print("\(result)")
            self?.createNewConversation(result:result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated:true)
    }
    
    //create a new conversation with a specified user
    private func createNewConversation(result: [String:String]){
        
        print("DEBUG: Create New Conversation!")
        
        //required to start a new conversation
        guard let name = result["name"], let email = result["email"] else {
            return
        }
        
        //create the chat view
        let vc = ChatViewController(with: email, id: nil) //this will be instantiated with a user !!! IMPORTANT FUTURE IMPLEMENTATION, can also copy for maps, probs pushing data through segue
        //set it to a new conversation
        vc.isNewConversation = true
        //set the title to be the recipients name
        vc.title = name
        //push to the view
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    //reload the data when the view appears
    override func viewWillAppear(_ animated: Bool){
        conversations = []
        fetchConversations()
        startListeningForConversations()
        tableView.reloadData()
    }
    
    override func viewDidLayoutSubviews(){
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    //when the view appears, validate the user
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    //check if the user is logged in
    //also useful for navigation purposes
    private func validateAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil{
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav,animated:false)
        }
    }
    
    private func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    //get the conversations from the database
    private func fetchConversations(){
        tableView.isHidden = false
    }

}

