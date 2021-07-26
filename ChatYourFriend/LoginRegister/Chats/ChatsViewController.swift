//
//  ChatsViewController.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 12.07.21.
//

import UIKit
import FirebaseAuth

 struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

 struct LatestMessage {
    let date: String
    let message: String
    let isRead: Bool
}

class ChatsViewController: UIViewController {
    
    private var conversations = [Conversation]()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        tableView.isHidden = true
        return tableView
    }()
    
    private let noDialogueLabel: UILabel = {
        let label = UILabel()
        label.text = "You don't have dialogues here. Start new dialogue."
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 22)
        label.textColor = .blue
        label.isHidden = true
        return label
    }()
    
    private var loginObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddButton))
        view.addSubview(tableView)
        view.addSubview(noDialogueLabel)
        setupTableView()
        fetchDialogues()
        startListeningForConversation()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLoginNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.startListeningForConversation()
        })
    }
    
    private func startListeningForConversation() {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: email)
        
        DatabaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
            switch result {
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    return
                }
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("failure \(error)")
            }
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateUser()

    }
    
    @objc private func didTapAddButton() {
        let controller = NewChatViewController()
        controller.completion = { [weak self] result in
            
            guard let strongSelf = self else {
                return
            }
            
            let currentConversations = strongSelf.conversations
            
            if let targetConversations = currentConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(email: result.userEmail)
            }) {
                let controller = ChatViewController(email: targetConversations.otherUserEmail, id: targetConversations.id)
                controller.isNewChat = false
                controller.title = targetConversations.name
                controller.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(controller, animated: true)
            } else {
                strongSelf.createNewConversation(result: result)
            }
    
        }
        let navigationController = UINavigationController(rootViewController: controller)
        present(navigationController, animated: true)
        
    }
    
    private func createNewConversation(result: SearchResult) {
        let name = result.userName
        let email = DatabaseManager.safeEmail(email: result.userEmail)
        
        DatabaseManager.shared.conversationExists(with: email) { [weak self] result in
            switch result {
            case .success(let conversationID):
                let controller = ChatViewController(email: email, id: conversationID)
                controller.isNewChat = false
                controller.title = name
                controller.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(controller, animated: true)
            case .failure(_):
                let controller = ChatViewController(email: email, id: nil)
                controller.isNewChat = true
                controller.title = name
                controller.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(controller, animated: true)
            }
        }
        
        
    }
    
    private func validateUser() {
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let controller = LoginViewController()
            let navigation = UINavigationController(rootViewController: controller)
            navigation.modalPresentationStyle = .fullScreen
            present(navigation, animated: false)
        }
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func fetchDialogues() {
        tableView.isHidden = false
    }


}

extension ChatsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        //cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = conversations[indexPath.row]
        openConversation(model)
        
    }
    
    func openConversation(_ model: Conversation) {
        let controller = ChatViewController(email: model.otherUserEmail, id: model.id)
                controller.title = model.name
                controller.navigationItem.largeTitleDisplayMode = .never
                navigationController?.pushViewController(controller, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //delete
            let conversationID = conversations[indexPath.row].id
            tableView.beginUpdates()
            
            DatabaseManager.shared.deleteConversation(conversationID: conversationID) { [weak self] success in
                if success {
                    self?.conversations.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .left)
                }
            }
            
            
            tableView.endUpdates()
        }
    }
}
