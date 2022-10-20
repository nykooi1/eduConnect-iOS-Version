//
//  ChatViewController.swift
//  EduConnect
//
//  Created by Noah Kim on 5/2/22.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType{
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

extension MessageKind{
    var messageKindString: String{
        switch self{
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attr text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType{
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

//the actual chat
class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false
    public let otherUserEmail: String
    private let conversationId: String?
    
    private var messages = [Message]()
    
    private let selfSender = Sender(photoURL: "", senderId: DatabaseManager.safeEmail(emailAddress: UserDefaults.standard.value(forKey: "email") as! String), displayName: "Joe Smith")
    
    //listens for new messages
    private func listenForMessages(id: String){
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: {[weak self] result in
            switch result{
            case.success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                DispatchQueue.main.async{
                    self?.messagesCollectionView.reloadData()
                }
            case.failure(let error):
                print("\(error)")
            }
        })
    }
    
    //constructor
    init(with email: String, id: String?){
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
        if let conversationId = conversationId{
            listenForMessages(id: conversationId)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        //dismiss the keyboard on drag
        messagesCollectionView.keyboardDismissMode = .onDrag
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate{
    
    //when the send button is clicked
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String){
        
        //if the text is blank
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            //do nothing
            return
        }
        
        //clear the input text view
        inputBar.inputTextView.text = ""
        
        print("Sending: \(text)")
        
        //otherwise, send the msssage
        
        let msg = Message(sender: selfSender, messageId: createMessageId(), sentDate: Date(), kind: .text(text))
        
        //if it is a new conversation
        if isNewConversation{
            //create
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name: self.title ?? "User", firstMessage: msg, completion: {[weak self] success in
                if(success){
                    print("message sent")
                    self?.isNewConversation = false
                    guard let navigationVC = self?.navigationController else { return }
                        navigationVC.popViewController(animated: false)
                } else {
                    print("failed to send")
                }
            })
        }
        //otherwise, there is an existing conversation
        else {
            //append
            guard let conversationId = conversationId else {
                return
            }
            guard let name = self.title else {
                return
            }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: otherUserEmail, name: name, message: msg, completion: {success in
                if success{
                    print("message sent")
                } else {
                    print("message failed to send")
                }
            })
        }
    }
    
    //creates a msg id
    private func createMessageId() -> String{
        //date, otherUseremail,senderEmail,randomInt
        let currentUserEmail = UserDefaults.standard.value(forKey: "email") as! String
        let currentSafeUserEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        let dateString = Self.dateFormatter.string(from: Date())
        let newID = "\(otherUserEmail)_\(currentSafeUserEmail)_\(dateString)"
        return newID
    }
}


extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}
