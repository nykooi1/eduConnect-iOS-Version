//
//  DatabaseManager.swift
//  EduConnect
//
//  Created by Noah Kim on 5/2/22.
//

import Foundation
import FirebaseDatabase
import SwiftUI
import CoreLocation

//need to think about what I am going to put in here
//once messaging is set up might be confusing with how I am going to let them search the users

//singleton MVC
final class DatabaseManager{
    
    //singelton instance
    static let shared = DatabaseManager()
    
    //gets a refrence to the database
    private let database = Database.database().reference()
    
    //converts an email adddress to be safe (removing characters for firebase key entry)
    static func safeEmail(emailAddress: String) -> String {
        var safeEmail  = emailAddress.replacingOccurrences(of:".", with:"-")
        safeEmail = safeEmail.replacingOccurrences(of:"@", with:"-")
        return safeEmail
    }
    
}

//functions which manage the REALTIME database
extension DatabaseManager{
    
    //check if the uesr exists
    public func userExists(with email: String, completion: @escaping((Bool) -> Void)){
        
        var safeEmail  = email.replacingOccurrences(of:".", with:"-")
        safeEmail = safeEmail.replacingOccurrences(of:"@", with:"-")
        
        //we want to query the datagbase once
        database.child(safeEmail).observeSingleEvent(of: .value, with:{snapshot in
            guard snapshot.value as? String != nil else{
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    //creates a new user with the email as the key
    public func insertUser(with user: EduConnectUser, completion: @escaping(Bool) -> Void){
        database.child(user.safeEmail).setValue([
            "first_name":user.firstName,
            "last_name":user.lastName,
            "instagram_username":user.instagramUsername,
            "major":user.major,
            "x_coordinate":user.xCoordinate,
            "y_coordinate":user.yCoordinate,
            "course_list":user.courseList,
            "club_list":user.clubList
        ], withCompletionBlock: { error, _ in
            guard error == nil else{
                print("failed to write to db")
                completion(false)
                return
            }
            
            //kind of confused on this design
            
            //try to get a reference to an existing users array in the database
            //this will be important when polling for the user location I think...
            self.database.child("users").observeSingleEvent(of: .value, with: {snapshot in
                if var usersCollection = snapshot.value as? [[String:Any]]{
                    //append to the user dictionary
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                        "email": user.safeEmail,
                        "major": user.major,
                        "x":0,
                        "y":0
                    ] as [String : Any]
                    usersCollection.append(newElement)
                    self.database.child("users").setValue(usersCollection, withCompletionBlock:{error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
                else {
                    //create the array
                    let newCollection: [[String:String]] = [
                        [
                            "name": user.firstName + " " + user.lastName,
                            "email": user.safeEmail
                        ]
                    ]
                    
                    self.database.child("users").setValue(newCollection, withCompletionBlock:{error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    })
                }
            })
        })
    }
    
    //get all the users
    public func getAllUsers(completion: @escaping(Result<[[String:String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value, with: {snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value)) //contains all the users
        })
    }
    
    //declare error type
    public enum DatabaseError:Error{
        case failedToFetch
    }

}

//sending messages / conversation
extension DatabaseManager{
    
    //creates new conversation with target email and first message sent
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping(Bool) -> Void) {
        
        //gets the current email of the user logged in
        var currentEmail: String {
            (UserDefaults.standard.value(forKey:"email") as? String)!
        }
        
        //get the current user name
        var currentName: String {
            (UserDefaults.standard.value(forKey: "name") as? String)!
        }
        
        //generates the safe email version
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        //gets a reference to the current user's node
        let ref = database.child("\(safeEmail)")
        
        //gets a snapshot
        ref.observeSingleEvent(of: .value, with: {[weak self] snapshot in
            
            //gets the user snapshot
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            //gets the message date
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            //get the actual message string
            var message = ""
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            default:
                 break
            }
            
            //construct the new conversation layout
            //the converation has an ID along with the other user's email and the latest message sent
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversationData = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message":[
                    "date":dateString,
                    "message": message,
                    "is_read": false
                ]
            ] as [String : Any]
            
            let recipient_newConversationData = [
                "id": conversationID,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message":[
                    "date":dateString,
                    "message": message,
                    "is_read": false
                ]
            ] as [String : Any]
            
            //update recipient conversation entry
            let otherSafeEmail = DatabaseManager.safeEmail(emailAddress: otherUserEmail)
            self?.database.child("\(otherSafeEmail)/conversations").observeSingleEvent(of: .value, with: {snapshot in
                if var conversations = snapshot.value as? [[String:Any]]{
                    //append
                    conversations.append(recipient_newConversationData)
                    //override with the newly appended conversation
                    self?.database.child("\(otherSafeEmail)/conversations").setValue(conversations)
                } else {
                    //create
                    self?.database.child("\(otherSafeEmail)/conversations").setValue([recipient_newConversationData])
                }
            })
            
            //update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //converation array exists
                //append
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                //re insert the updated user node into the reference
                ref.setValue(userNode, withCompletionBlock: {[weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    //not only do you want to put it in the user's conversation list, you want to create the convo itself
                    self?.finishCreatingConversation(conversationID: conversationID, name:name, firstMessage: firstMessage, completion: completion)
                    completion(true)
                })
            }
            //the conversation array does not exist
            else {
                
                //does not exist
                //create it
                
                //instantiate the conversations array in the user node
                //put this conversation into the user's conversation list
                userNode["conversations"] = [
                    newConversationData
                ]
                //re insert the updated user node into the reference
                ref.setValue(userNode, withCompletionBlock: {[weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    //not only do you want to put it in the user's conversation list, you want to create the convo itself
                    self?.finishCreatingConversation(conversationID: conversationID, name:name, firstMessage: firstMessage, completion: completion)
                    completion(true)
                })
            }
        })
    }
    
    
    //not only do I want to add the conversation to the user node...
    //I want to create a separate conversation node so we can query all the messages added to it in real time
    private func finishCreatingConversation(conversationID: String, name: String, firstMessage: Message, completion: @escaping(Bool) -> Void){
        
        //get the actual message string
        var content = ""
        switch firstMessage.kind {
        case .text(let messageText):
            content = messageText
        default:
             break
        }
        
        //gets the message date
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        //current email (sender)
        var currentEmail: String {
            (UserDefaults.standard.value(forKey:"email") as? String)!
        }
        let currentSafeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail);
        
        let collectionMessage: [String : Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "name": name,
            "content": content,
            "date": dateString,
            "sender_email":currentSafeEmail,
            "is_read":false
        ]
        
        let value: [String:Any] = [
            "messages":[
                collectionMessage
            ]
        ]
        
        //create the conversation in the database
        database.child("\(conversationID)").setValue(value, withCompletionBlock:{error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    /*
     
     Quick Summary:
     
     When opening a NEW conversation,
     1) Add the conversation to the user node
     2) Create the conversation node itself to store the messages
     
     */
    
    //return all the conversations that the user is in
    public func getAllConversations(for email: String, completion: @escaping(Result<[Conversation], Error>) -> Void){
        print("DEBUG: \(email)/conversations")
        database.child("\(email)/conversations").observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap({dictionary in
                guard let conversationId = dictionary["id"] as? String else {
                          print("DEBUG: RETURN NIL 1")
                          return nil
                      }
                guard let name = dictionary["name"] as? String else {
                          print("DEBUG: RETURN NIL 2")
                          return nil
                      }
                guard let otherUserEmail = dictionary["other_user_email"] as? String else {
                          print("DEBUG: RETURN NIL 3")
                          return nil
                      }
                guard let latestMessage = dictionary["latest_message"] as? [String: Any] else {
                          print("DEBUG: RETURN NIL 4")
                          return nil
                      }
                guard let date = latestMessage["date"] as? String else {
                          print("DEBUG: RETURN NIL 5")
                          return nil
                      }
                guard let message = latestMessage["message"] as? String else {
                          print("DEBUG: RETURN NIL 6")
                          return nil
                      }
                guard let isRead = latestMessage["is_read"] as? Bool else {
                          print("DEBUG: RETURN NIL 7")
                          return nil
                      }
                let latestMessageObject = LatestMessage(date:date, text:message, isRead:isRead)
                return Conversation(id:conversationId, name:name, otherUserEmail:otherUserEmail, latestMessage:latestMessageObject)
            })
            completion(.success(conversations))
        })
    }
    
    //get all the messages for a conversation
    //listens for changes by observing the node of messages
    public func getAllMessagesForConversation(with id: String, completion: @escaping(Result<[Message], Error>) -> Void){
        database.child("\(id)/messages").observe(.value, with: {snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap({dictionary in
                guard let name = dictionary["name"] as? String,
                      //let isRead = dictionary["is_read"] as? Bool,
                      let id = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      //let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                          return nil
                      }
                let sender = Sender(photoURL:"",
                                    senderId: senderEmail,
                                    displayName: name)
                
                return Message(sender: sender, messageId: id, sentDate: date, kind: .text(content))
            })
            completion(.success(messages))
        })
    }
    
    //send a message to a conversation
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, message: Message, completion: @escaping(Bool) -> Void){
        
        print("DEBUG: send message to " + name)
        
        //1) add new message to messages
        //2) update sender latest message
        //3) update recipient latest message
        
        /*guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }*/
        
        var currentEmail: String {
            (UserDefaults.standard.value(forKey:"email") as? String)!
        }
        let currentSafeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail);
            
        //current email (sender)
        //let currentEmail = UserDefaults.standard.value(forKey:"email") as! String
        //let currentSafeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)

        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value, with:{[weak self] snapshot in
            
            guard let strongSelf = self else {
                return
            }
            
            guard var currentMessages = snapshot.value as? [[String:Any]] else {
                completion(false)
                return
            }
            
            //get the actual message string
            var content = ""
            switch message.kind {
            case .text(let messageText):
                content = messageText
            default:
                 break
            }
            
            //gets the message date
            let messageDate = message.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            let newMessageEntry: [String : Any] = [
                "id": message.messageId,
                "type": message.kind.messageKindString,
                "name": name,
                "content": content,
                "date": dateString,
                "sender_email":currentSafeEmail,
                "is_read":false
            ]
            
            //adds the message to the array
            currentMessages.append(newMessageEntry)
            
            //update the database
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) {error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                //do the updates for the latest messages for both people
                
                //need the conversation node for each user
                
                //then find the conversation Id and udpate the latest message field
                
                strongSelf.database.child("\(currentSafeEmail)/conversations").observeSingleEvent(of: .value, with: {snapshot in
                    
                    //one thing I am confused about is the below snapshot
                    /*
                     
                     It is a snapshot of /conversations
                     
                     which is an array of objects
                     
                     So why is it "String"
                     
                     it is an ARRAY of dictionaries
                     
                     */
                    
                    //get a snapshot of the current user conversations which is a map of a string to something
                    guard var currentUserConversations = snapshot.value as? [[String:Any]] else {
                        completion(false)
                        return
                    }
                    
                    //update the latest message in the conversation
                    let updatedValue: [String:Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": content
                        ]
                    
                    var position = 0
                    
                    var targetConversation: [String:Any]?
                    
                    //loop through the snapshot map
                    for existingConversation in currentUserConversations{
                        //find the conversation with the correct id
                        if let currentId = existingConversation["id"] as? String, currentId == conversation{
                            targetConversation = existingConversation
                            break
                        }
                        position += 1
                    }
                    
                    //update the latest message field
                    targetConversation?["latest_message"] = updatedValue
                    
                    //unwrap the targetConversation
                    guard let targetConversation = targetConversation else {
                        completion(false)
                        return
                    }
                    
                    //update the user's conversation array
                    currentUserConversations[position] = targetConversation
                    //update the database
                    strongSelf.database.child("\(currentSafeEmail)/conversations").setValue(currentUserConversations, withCompletionBlock: {error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        //update the latest message for recipient
                        
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: {snapshot in
                            
                            //get a snapshot of the current user conversations which is a map of a string to something
                            guard var otherUserConversations = snapshot.value as? [[String:Any]] else {
                                completion(false)
                                return
                            }
                            
                            //update the latest message in the conversation
                            let updatedValue: [String:Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": content
                                ]
                            
                            var position = 0
                            
                            var targetConversation: [String:Any]?
                            
                            //loop through the snapshot map
                            for existingConversation in otherUserConversations{
                                //find the conversation with the correct id
                                if let currentId = existingConversation["id"] as? String, currentId == conversation{
                                    targetConversation = existingConversation
                                    break
                                }
                                position += 1
                            }
                            
                            //update the latest message field
                            targetConversation?["latest_message"] = updatedValue
                            
                            //unwrap the targetConversation
                            guard let targetConversation = targetConversation else {
                                completion(false)
                                return
                            }
                            
                            //update the user's conversation array
                            otherUserConversations[position] = targetConversation
                            //update the database
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations, withCompletionBlock: {error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            })
                        })
                        completion(true)
                    })
                })
            }
        })
    }
    
}

//edit info handling
extension DatabaseManager{
    
    //get the user information
    public func getUserInformationAsStruct(safeEmailAddress: String, completion: @escaping(Result<Any, Error>) -> Void){
        //take a snapshot of the user's conversations
        self.database.child("\(safeEmailAddress)").observeSingleEvent(of: .value) {snapshot in
            
            //read in the snapshot value as an array of dictionaries (which it is)
            guard let userInformation = snapshot.value as? [String:Any] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            var courses: [String] = [] //empty array
            
            //if there are courses, set them
            if(userInformation["courses"] != nil){
                courses = userInformation["courses"] as! [String]
            }
            
            //return the list on completion
            completion(.success(courses))
        }
    }
    
    //update the user courses
    public func updateUserCourses(safeEmailAddress: String, courses: [String], completion: @escaping(Result<Any, Error>) -> Void){
        
        //take a snapshot of the user
        self.database.child("\(safeEmailAddress)").observeSingleEvent(of: .value) {snapshot in
            
            //read in the snapshot value as an array of dictionaries (which it is)
            guard var userInformation = snapshot.value as? [String:Any] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }

            //set the user courses
            userInformation["courses"] = courses
            
            self.database.child("\(safeEmailAddress)").setValue(userInformation)
            
            //return the list on completion
            completion(.success(courses))
        }
    }
}


//opening profile
extension DatabaseManager{
    
    //get all the conversation IDs for a user and return it
    public func getConversationIds(safeEmailAddress: String, completion: @escaping(Result<Any, Error>) -> Void){
        
        //take a snapshot of the user's conversations
        self.database.child("\(safeEmailAddress)/conversations").observeSingleEvent(of: .value) {snapshot in
            
            //read in the snapshot value as an array of dictionaries (which it is)
            guard let conversations = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            //initialize conversationIds list
            var conversationIds: [String] = []
            
            //loop through the conversations and pull out the ids
            for conversation in conversations{
                conversationIds.append(conversation["id"] as! String)
            }
        
            completion(.success(conversationIds))
        }
    }
    
    //get the user information
    public func getUserInformation(safeEmailAddress: String, completion: @escaping(Result<Any, Error>) -> Void){
        //take a snapshot of the user's conversations
        self.database.child("\(safeEmailAddress)").observeSingleEvent(of: .value) {snapshot in
            
            //read in the snapshot value as an array of dictionaries (which it is)
            guard let userInformation = snapshot.value as? [String:Any] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            //return the list on completion
            completion(.success(userInformation))
        }
    }
    
    
}

//getters
extension DatabaseManager{
    public func getDataFor(path: String, completion: @escaping(Result<Any, Error>) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value) {snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

//managing location queries
extension DatabaseManager{
    
    //set the x and y coordinate for a user
    public func setLocation(emailAddress: String, x: Double, y:Double, completion: @escaping(Result<Any, Error>) -> Void){
        
        //get a snapshot of the users
        self.database.child("users/").observeSingleEvent(of: .value) {snapshot in
            
            //read in the snapshot value as an array of dictionaries (which it is)
            guard var allUsers = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            print("DEBUGv2: \(allUsers)")
            
            var position = 0
            
            var targetUser: [String:Any]?
            
            //loop through each snapshot and find the one I want
            for vUser in allUsers{
                //If I find the user I am looking for, need to update this entry
                if(vUser["email"] as! String == emailAddress){
                    targetUser = vUser
                    break
                }
                position += 1;
            }
            
            //update the target user x and y
            targetUser?["x"] = x;
            targetUser?["y"] = y;
            //update the array
            allUsers[position] = targetUser!
            
            //update the database
            self.database.child("users/").setValue(allUsers)
            
            //return the individual user object to the completion
            completion(.success(targetUser!))
        }
    }
    
    //get the distance between 2 coordinates - in meters using CoreLocation
    public func getDistance(x1: Double, y1: Double, x2: Double, y2: Double) -> Double{
        let coordinate1 = CLLocation(latitude: x1, longitude: y1)
        print("\(x1),\(y1)")
        print("\(x2),\(y2)")
        let coordinate2 = CLLocation(latitude: x2, longitude: y2)
        let distanceInMeters = coordinate1.distance(from: coordinate2) // result is in meters
        return distanceInMeters
    }
    
    //get a list of nearby users
    public func getNearbyUsers(emailAddress:String, x:Double, y:Double, completion: @escaping(Result<Any, Error>) -> Void){
        
        print("Get Nearby Users")
        
        //get the users nearby the specifed user (safe email)
        
        //get a snapshot of the users
        self.database.child("users/").observeSingleEvent(of: .value) { [self]snapshot in
            
            //read in the snapshot value as an array of dictionaries (which it is)
            guard let allUsers = snapshot.value as? [[String:Any]] else {
                print(snapshot.value!)
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            //store the list of nearby users
            var nearbyUsers: [NearbyUser] = []
            
            //loop through each snapshot and find the one I want
            for vUser in allUsers{
                print(vUser)
                //only compare to users that arent the current user
                if(vUser["email"] as! String != emailAddress){
                    //check if the x and y coordinate are set
                    if(vUser["x"] != nil && vUser["y"] != nil){
                        //finally, check if it is within the radius (30 meters or roughly 100 feet)
                        let distance = self.getDistance(x1: x, y1: y, x2: vUser["x"] as! Double, y2: vUser["y"] as! Double)
                        print("distance: \(distance)")
                        //if it is within the radius, add it to the list
                        if(distance <= 30){
                            //construct the nearbyUser
                            let nearbyUser = NearbyUser(name: vUser["name"] as! String,
                                                        safeEmail: vUser["email"] as! String,
                                                        major: vUser["major"] as! String,
                                                        profilePic: "\(vUser["email"] as! String)_profile_picture.png")
                            nearbyUsers.append(nearbyUser)
                        }
                    }
                }
            }
            print("DEBUG - Nearby Users From DB:")
            print(nearbyUsers)
            //return the individual user object to the completion
            completion(.success(nearbyUsers))
        }
        
        
    }
}

//user struct object
struct EduConnectUser{
    let firstName: String
    let lastName: String
    let emailAddress: String
    let instagramUsername: String
    let major: String
    let xCoordinate: Double //x location from google maps
    let yCoordinate: Double //y location from google maps
    //lists of courses and clubs (added after user has been created)
    let courseList: [String]
    let clubList: [String]
    
    var safeEmail: String{
        var safeEmail  = emailAddress.replacingOccurrences(of:".", with:"-")
        safeEmail = safeEmail.replacingOccurrences(of:"@", with:"-")
        return safeEmail
    }
    
    var profilePictureFileName: String{
        return "\(safeEmail)_profile_picture.png"
    }
}
