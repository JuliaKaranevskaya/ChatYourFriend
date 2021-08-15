//
//  MessengerUser.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 13.08.21.
//

import Foundation

struct MessengerUser {
    let firstName: String
    let lastName: String
    let email: String
    
    var safeEmail: String {
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var userPictureName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}
