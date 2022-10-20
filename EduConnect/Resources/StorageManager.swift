//
//  StorageManager.swift
//  EduConnect
//
//  Created by Noah Kim on 5/2/22.
//

import Foundation
import FirebaseStorage

final class StorageManager{
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    //standardized storage path
    // /images/nykim-usc-edu_profile_picture.png
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    //Upload picture to firebase storage and returns the completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping(UploadPictureCompletion)){
        storage.child("images/\(fileName)").putData(data, metadata:nil, completion: {metadata, error in
            guard error == nil else{
                //failed
                print("failed to upload photo to firebase")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            //get the url
            self.storage.child("images/\(fileName)").downloadURL(completion: {url, error in
                guard let url = url else{
                    print("failed to get url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                let urlString = url.absoluteString
                completion(.success(urlString))
            })
        })
    }
    
    public enum StorageErrors: Error{
        case failedToUpload
        case failedToGetDownloadUrl
    }
    
    //return the download url
    public func downloadURL(for path: String, completion: @escaping (Result<URL, Error>) -> Void){
        //gets the reference to the specified image within the firestore storage
        let reference = storage.child(path)
        //return the completion failure / success
        reference.downloadURL(completion: {url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            print(url)
            completion(.success(url))
        })
    }
}
