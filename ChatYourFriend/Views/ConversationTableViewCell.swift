//
//  ConversationTableViewCell.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 18.07.21.
//

import UIKit

class ConversationTableViewCell: UITableViewCell {
    
    static let identifier = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 35
        iv.layer.masksToBounds = true
        return iv
    }()
    
    private let userNameLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 21, weight: .semibold)
        return l
    }()
    
    private let userMessageLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 19, weight: .regular)
        l.numberOfLines = 0
        return l
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        userImageView.frame = CGRect(x: 10, y: 10, width: 70, height: 70)
        
        userNameLabel.frame = CGRect(x: userImageView.frame.size.width + 10 + 10, y: 10, width: contentView.frame.size.width - userImageView.frame.size.width - 20, height: (contentView.frame.size.height - 20) / 2)
        
        userMessageLabel.frame = CGRect(x: userImageView.frame.size.width + 10 + 10, y: (contentView.frame.size.height - 20) / 2 + 10, width: contentView.frame.size.width - userImageView.frame.size.width - 20, height: (contentView.frame.size.height - 20) / 2)
        
    }
    
    public func configure(with model: Conversation) {
        self.userMessageLabel.text = model.latestMessage.message
        self.userNameLabel.text = model.name
        
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
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
