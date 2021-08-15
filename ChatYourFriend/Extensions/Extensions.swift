//
//  Extensions.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 25.07.21.
//

import Foundation
import UIKit

//убирать клавиатуру с экрана по на жатию на любую область экрана
extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
