//
//  NewConversationCell.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 25.07.21.
//

import UIKit
import SDWebImage

class NewChatCell: UITableViewCell {
    
    static let identifier = "NewChatCell"
    
    private let userImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 35
        iv.layer.masksToBounds = true
        return iv
    }()
    
    private let userPersonalLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 21, weight: .semibold)
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userPersonalLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10, y: 10, width: 70, height: 70)
        
        userPersonalLabel.frame = CGRect(x: userImageView.frame.size.width + 10 + 10, y: 20, width: contentView.frame.size.width - userImageView.frame.size.width - 20, height: 50)
        
    }
    
    public func configure(with model: SearchResult) {
       
        self.userPersonalLabel.text = model.userName
        
        let path = "images/\(model.userEmail)_profile_picture.png"
        StorageManager.shared.downloadURL(path: path) { [weak self] result in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print("failed to get image url: \(error)")
            }
        }
    }
}

