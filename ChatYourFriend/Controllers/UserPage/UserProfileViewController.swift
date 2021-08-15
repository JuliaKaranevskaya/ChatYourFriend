//
//  UserProfileViewController.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 12.07.21.
//

import UIKit
import FirebaseAuth
import SDWebImage

class UserProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let userProfileName = UserDefaults.standard.value(forKey: "name") as? String ?? "No name"
    let userProfileEmail = UserDefaults.standard.value(forKey: "email") as? String ?? "No email"
    var userInfo = [String]()
    
    let tableView: UITableView = {
        let tv = UITableView()
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        
        tableView.frame = view.bounds
        tableView.separatorColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = setupTableViewHeader()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Log out", style: .done, target: self, action: #selector(didTapLogout))
        
        userInfo.append(userProfileName)
        userInfo.append(userProfileEmail)
    }
    
    @objc private func didTapLogout() {
        let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { [weak self] action in
            
            UserDefaults.standard.setValue(nil, forKey: "name")
            UserDefaults.standard.setValue(nil, forKey: "email")
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                
                let controller = LoginViewController()
                let navigation = UINavigationController(rootViewController: controller)
                navigation.modalPresentationStyle = .fullScreen
                self?.present(navigation, animated: true)
                
            } catch  {
                print("Failed to sing out operation")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    func setupTableViewHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(email: email as! String)
        let path = "images/" + safeEmail + "_profile_picture.png"
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 300))
       
        
        let imageView = UIImageView(frame: CGRect(x: (containerView.frame.width - 150) / 2, y: 75, width: 150, height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = imageView.frame.height / 2
        containerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(path: path) { result in
            switch result {
            
            case .success(let url):
                imageView.sd_setImage(with: url, completed: nil)

            case .failure(let error):
                print("Failed to get url \(error)")
            }
        }
        
        return containerView
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userInfo.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = userInfo[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .black
        cell.selectionStyle = .none
        return cell
    }
}

