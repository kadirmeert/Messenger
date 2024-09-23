//
//  ChatViewController.swift
//  Messenger
//
//  Created by Kadir Yildiz on 19/9/2024.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    var sender: any MessageKit.SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKit.MessageKind
}

struct Sender : SenderType {
    var photoURL: String
    var senderId: String
    var displayName: String
}

class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public var isNewConversation = false
    public var otherUserEmail: String
    
    private var messages = [Message]()
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { return nil }
        
        return Sender(photoURL: "",
                      senderId: email,
                      displayName: "Kadir Yildiz")
    }
    
    init(with email: String) {
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
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

    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()

    }

}
extension ChatViewController: InputBarAccessoryViewDelegate {
   
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: "", with: "").isEmpty,
        let selfSender = self.selfSender,
        let messageId = createMessageId() else {
            return
        }
        if isNewConversation {
            // create conversation in database
            let message = Message(sender: selfSender,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .text(text))
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, firstMessage: message, completion: { success in
                if success {
                    print("message sent")
                } else {
                    print("Error sending message")
                }
            })
        }
        else {
            
        }
    }
    private func createMessageId() -> String? {
        
        guard let currentUserEmail = UserDefaults.standard.string(forKey: "email") else {
            return nil
        }
        let dateString = Self.dateFormatter.string(from: Date())
        let newId = "\(otherUserEmail)_\(currentUserEmail)"
        
        return newId
    }
}
extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> any MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self Sender is nil, email is not set")
        return Sender(photoURL: "", senderId: "12", displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> any MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
