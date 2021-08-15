//
//  NewViewController.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 12.07.21.
//

import UIKit

class NewChatViewController: UIViewController {
    
    public var completion: ((SearchResult) -> (Void))?
 
    private var users = [[String: String]]()
    
    private var results = [SearchResult]()
    
    private var didFindUser = false
    
    private let searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "Look for your friends"
        return bar
    }()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.isHidden = true
        tableView.register(NewChatCell.self, forCellReuseIdentifier: NewChatCell.identifier)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(closeNewChatVC))
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    @objc private func closeNewChatVC() {
        dismiss(animated: true, completion: nil)
    }
}

//MARK: - TableView methods
extension NewChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewChatCell.identifier, for: indexPath) as! NewChatCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let neededUser = results[indexPath.row]
        dismiss(animated: true) { [weak self] in
            self?.completion?(neededUser)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

//MARK: - Searching methods
extension NewChatViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return 
        }
        searchBar.resignFirstResponder()
        results.removeAll()
        self.searchUsers(query: text)
    }
    
    func searchUsers(query: String) {
        if didFindUser {
            filterUsers(with: query)
            
        } else {
            DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                switch result {
                case .success(let userCollection):
                    self?.didFindUser = true
                    self?.users = userCollection
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("Fail to get users \(error)")
                }
            })
        }
    }
    
    func filterUsers(with term: String) {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String,
            didFindUser else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(email: currentUserEmail)
        
        let results: [SearchResult] = self.users.filter ({
            
            guard let email = $0["email"],
                  email != safeEmail else {
                return false
            }
            
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap {
            guard let email = $0["email"],
                  let name = $0["name"] else {
                return nil
            }
            return SearchResult(userName: name, userEmail: email)
        }
        self.results = results
        updatePage()
    }
    
    func updatePage() {
        if results.isEmpty {
            self.tableView.isHidden = true
        } else {
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}


