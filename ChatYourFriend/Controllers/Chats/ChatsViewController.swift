//
//  ChatsViewController.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 12.07.21.
//

import UIKit
import FirebaseAuth

class ChatsViewController: UIViewController {

    private var conversations = [Conversation]()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return tableView
    }()
    
    private var loginObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAddButton))
        
        view.addSubview(tableView)
       
        tableView.delegate = self
        tableView.dataSource = self
        
        fetchDialogues()
        startListeningForConversation()
        
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name("didLoginNotification"), object: nil, queue: .main, using: { [weak self] _ in
           
            self?.startListeningForConversation()
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
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
    

    

    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateUser()

    }
    
    @objc private func didTapAddButton() {
        
        let controller = NewChatViewController()
        
        controller.completion = { [weak self] result in
            
            let currentConversations = self?.conversations
            
            if let targetConversations = currentConversations?.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(email: result.userEmail)
            }) {
                let controller = ChatViewController(email: targetConversations.otherUserEmail, id: targetConversations.id)
                controller.isNewChat = false
                controller.title = targetConversations.name
                controller.navigationItem.largeTitleDisplayMode = .never
                self?.navigationController?.pushViewController(controller, animated: true)
            } else {
                self?.createNewConversation(result: result)
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

    private func fetchDialogues() {
        tableView.isHidden = false
        
    }
}

//MARK: - TableView Delegate & Datasource Methods
extension ChatsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        cell.accessoryType = .disclosureIndicator
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
        return 90
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
       
        if editingStyle == .delete {
            let conversationID = conversations[indexPath.row].id
            tableView.beginUpdates()
            self.conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            
            DatabaseManager.shared.deleteConversation(conversationID: conversationID) { success in
                if success {
                  print("Success")
                }
            }
            
            tableView.endUpdates()
        }
    }
}
