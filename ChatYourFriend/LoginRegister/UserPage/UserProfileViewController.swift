//
//  UserProfileViewController.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 12.07.21.
//

import UIKit
import FirebaseAuth

class UserProfileViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let data = ["Log out"]
    
    let tableView: UITableView = {
        let tv = UITableView()
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.frame = view.bounds
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = setupTableViewHeader()

        
    }
    
    func setupTableViewHeader() -> UIView? {
        guard let email = UserDefaults.standard.value(forKey: "email") else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(email: email as! String)
        let path = "images/" + safeEmail + "_profile_picture.png"
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 300))
        containerView.backgroundColor = .yellow
        
        let imageView = UIImageView(frame: CGRect(x: (containerView.frame.width - 150) / 2, y: 75, width: 150, height: 150))
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.masksToBounds = true
        imageView.backgroundColor = .white
        imageView.layer.cornerRadius = imageView.frame.height / 2
        containerView.addSubview(imageView)
        
        StorageManager.shared.downloadURL(path: path) { [weak self] result in
            switch result {
            case .success(let url):
                self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("Failed to get url \(error)")
            }
        }
        
        return containerView
    }
    
    func downloadImage(imageView: UIImageView, url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else { return }
            
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                imageView.image = image
            }
        }.resume()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .blue
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { [weak self] action in
            
            guard let strongSelf = self else {
                return
            }
            
            
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                
                let controller = LoginViewController()
                let navigation = UINavigationController(rootViewController: controller)
                navigation.modalPresentationStyle = .fullScreen
                strongSelf.present(navigation, animated: true)
                
            } catch  {
                print("Failed sing out")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
        

    }


}

