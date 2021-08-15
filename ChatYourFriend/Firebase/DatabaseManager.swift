//
//  FirebaseDatabase.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 12.07.21.
//

import Foundation
import FirebaseDatabase

class DatabaseManager {
    
    static let shared = DatabaseManager()
    private init() {}

    private let databaseRef = Database.database().reference()
    
    static func safeEmail(email: String) -> String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

//MARK: - Account management

extension DatabaseManager {
    
    public func validateNewUser(by email: String, completion: @escaping ((Bool) -> Void)) {
        
        let safeEmail = DatabaseManager.safeEmail(email: email)
        
        databaseRef.child(safeEmail).observeSingleEvent(of: .value) { dataSnapshot in
            
            //completion: oldUser
            guard dataSnapshot.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
  
    public func addUser(user: MessengerUser, completion: @escaping (Bool) -> Void) {
     
        databaseRef.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
        ], withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            
            self.databaseRef.child("users").observeSingleEvent(of: .value, with: { snapshot in
                if var userCollection = snapshot.value as? [[String: String]] {
                    let newElement = [
                        "name": user.firstName + " " + user.lastName,
                         "email": user.safeEmail
                    ]
                    userCollection.append(newElement)
                   
                    self.databaseRef.child("users").setValue(userCollection, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                    completion(true)
                    })

                    
                } else {
                   
                    let newCollection: [[String: String]] = [
                        [
                        "name": user.firstName + " " + user.lastName,
                         "email": user.safeEmail
                    ]
                    ]
                    self.databaseRef.child("users").setValue(newCollection, withCompletionBlock: { error, _ in
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
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void) {
        databaseRef.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                completion(.failure(DataBaseError.failToGetUser))
                return
            }
            completion(.success(value))
        })
    }
}

public enum DataBaseError: Error {
    case failToGetUser
}

//MARK: - Conversations logic
extension DatabaseManager {
   
    public func createNewConversation(with otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {

        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: currentEmail)
        
        let reference = databaseRef.child(safeEmail)
        
        reference.observeSingleEvent(of: .value) { [weak self] snapshot in
            
            guard var userNode = snapshot.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_), .photo(_), .video(_), .location(_), .emoji(_), .audio(_), .contact(_), .linkPreview(_), .custom(_):
                break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipientNewConversationData: [String: Any] = [
                "id": conversationID,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]

            self?.databaseRef.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    conversations.append(recipientNewConversationData)
                    self?.databaseRef.child("\(otherUserEmail)/conversations").setValue(conversations)
                } else {
                    self?.databaseRef.child("\(otherUserEmail)/conversations").setValue([recipientNewConversationData])
                }
            }
  
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                reference.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                }
                
            } else {
                userNode["conversations"] = [
                    newConversationData
                ]
                
                reference.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                   
                    self?.finishCreatingConversation(name: name, conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                }
            }
        }
    }
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_), .photo(_), .video(_), .location(_), .emoji(_), .audio(_), .contact(_), .linkPreview(_), .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]
        
        let value: [String: Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        databaseRef.child(conversationID).setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
        
    }
    
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        databaseRef.child("\(email)/conversations").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DataBaseError.failToGetUser))
                return
            }
            
            let conversations: [Conversation] = value.compactMap { dictionary in
                guard let conversationID = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                
                let latestMessageObject = LatestMessage(date: date, message: message, isRead: isRead)
                
                return Conversation(id: conversationID, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
                      
            }
            
            completion(.success(conversations))
        }
        
    }
    
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        databaseRef.child("\(id)/messages").observe(.value) { snapshot in
            guard let value = snapshot.value as? [[String: Any]] else {
                completion(.failure(DataBaseError.failToGetUser))
                return
            }
            
            let messages: [Message] = value.compactMap { dictionary in
                guard let content = dictionary["content"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let messageID = dictionary["id"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let name = dictionary["name"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString) else {
                    return nil
                }
                
                let sender = Sender(pictureURL: "", senderId: senderEmail, displayName: name)
                
                return Message(sender: sender, messageId: messageID, sentDate: date, kind: .text(content))
                      
            }
            
            completion(.success(messages))
        }
        
    }
    
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentEmail = DatabaseManager.safeEmail(email: myEmail)
        
        databaseRef.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self] snapshot in
        
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_), .photo(_), .video(_), .location(_), .emoji(_), .audio(_), .contact(_), .linkPreview(_), .custom(_):
                break
            }
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentUserEmail = DatabaseManager.safeEmail(email: myEmail)
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            currentMessages.append(newMessageEntry)
            self?.databaseRef.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                self?.databaseRef.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                    var databaseEntryConversation = [[String: Any]]()
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    if var currentUserConversations = snapshot.value as? [[String: Any]]  {
                        
                        
                        var targetConversation: [String: Any]?
                        var position = 0
                        
                        for conversationDictionary in currentUserConversations {
                            if let currentID = conversationDictionary["id"] as? String, currentID == conversation {
                            targetConversation = conversationDictionary
                                break
                            }
                            position += 1
                        }
                        
                        if var targetConversation = targetConversation {
                            targetConversation["latest_message"] = updatedValue
                            currentUserConversations[position] = targetConversation
                            databaseEntryConversation = currentUserConversations
                        } else {
                            let newConversationData: [String: Any] = [
                                "id": conversation,
                                "other_user_email": DatabaseManager.safeEmail(email: otherUserEmail),
                                "name": name,
                                "latest_message": updatedValue
                            ]
                            currentUserConversations.append(newConversationData)
                            databaseEntryConversation = currentUserConversations
                        }
                        
                    } else {
                        let newConversationData: [String: Any] = [
                            "id": conversation,
                            "other_user_email": DatabaseManager.safeEmail(email: otherUserEmail),
                            "name": name,
                            "latest_message": updatedValue
                        ]
                        databaseEntryConversation = [
                            newConversationData
                        ]
                    }
                    
                   
                    self?.databaseRef.child("\(currentEmail)/conversations").setValue(databaseEntryConversation) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        //update latest message for recipient
                        
                        self?.databaseRef.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
                            
                            var databaseEntryConversation = [[String: Any]]()
                            
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                                return
                            }
                            
                            if var otherUserConversations = snapshot.value as? [[String: Any]]  {
                                
                                var targetConversation: [String: Any]?
                                var position = 0
                                
                                for conversationDictionary in otherUserConversations {
                                    if let currentID = conversationDictionary["id"] as? String, currentID == conversation {
                                    targetConversation = conversationDictionary
                                        break
                                    }
                                    position += 1
                                }
                                
                                if var targetConversation = targetConversation {
                                    targetConversation["latest_message"] = updatedValue
                                    otherUserConversations[position] = targetConversation
                                    databaseEntryConversation = otherUserConversations
                                } else {
                                    //failed to find in current collection
                                    let newConversationData: [String: Any] = [
                                        "id": conversation,
                                        "other_user_email": DatabaseManager.safeEmail(email: currentEmail),
                                        "name": currentName,
                                        "latest_message": updatedValue
                                    ]
                                    otherUserConversations.append(newConversationData)
                                    databaseEntryConversation = otherUserConversations
                                }
                            
                            } else {
                                //current collection doesn't exist
                                let newConversationData: [String: Any] = [
                                    "id": conversation,
                                    "other_user_email": DatabaseManager.safeEmail(email: currentEmail),
                                    "name": currentName,
                                    "latest_message": updatedValue
                                ]
                                databaseEntryConversation = [
                                    newConversationData
                                ]
                            }
                            
                      
                            self?.databaseRef.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversation) { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }

                                
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: function for LoginVC to signup user with firebase
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        self.databaseRef.child(path).observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DataBaseError.failToGetUser))
                return
            }
            return completion(.success(value))
        }
    }
    
    public func deleteConversation(conversationID: String, completion: @escaping (Bool) -> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: email)
        let reference = databaseRef.child("\(safeEmail)/conversations")
        reference.observeSingleEvent(of: .value) { snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String,
                       id == conversationID {
                        break
                    }
                    positionToRemove += 1
                }
                conversations.remove(at: positionToRemove)
                reference.setValue(conversations) { error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    completion(true)
                }
            }
        }
    }
    
    public func conversationExists(with targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        let safeRecipientEmail = DatabaseManager.safeEmail(email: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(email: senderEmail)
        
        databaseRef.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value) { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DataBaseError.failToGetUser))
                return
            }
            
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                //get id
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DataBaseError.failToGetUser))
                    return
                }
                
                completion(.success(id))
                return
            }
            completion(.failure(DataBaseError.failToGetUser))
            return
        }
    }
}


