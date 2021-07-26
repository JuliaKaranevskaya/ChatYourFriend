//
//  File.swift
//  ChatYourFriend
//
//  Created by Юлия Караневская on 12.07.21.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storageRef = Storage.storage().reference()
    
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping (Result<String, Error>) -> Void) {
        storageRef.child("images/\(fileName)").putData(data, metadata: nil) { metadata, error in
            guard error == nil else {
                completion(.failure(error!))
                return
            }
        }
        
        self.storageRef.child("images/\(fileName)").downloadURL { url, error in
            guard let url = url else {
                completion(.failure(error!))
                return
            }
            let urlString = url.absoluteString
            completion(.success(urlString))
        }
    }
    
    public enum StorageError: Error {
        case failToUpload
        case failToGetDownloadUrl
    }
    
    public func downloadURL(path: String, completion: @escaping (Result<URL, Error>) -> Void) {
        let reference = storageRef.child(path)
        
        reference.downloadURL { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageError.failToGetDownloadUrl))
                return }
            
            completion(.success(url))
        }
        
    }
}
