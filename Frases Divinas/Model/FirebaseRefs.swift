//
//  FirebaseRefs.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 27/03/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import Foundation
import Firebase

enum DatabaseRef {
    
    case root
    case users(uid: String)
    
    func reference() -> DatabaseReference {
        
        switch self {
        case .root:
            return rootRef
        default:
            return rootRef.child(path)
        }
    }
    private var rootRef: DatabaseReference {
        return Database.database().reference()
    }
    
    private var path: String {
        switch self {
        case .root:
            return ""
        case .users(let uid):
            return "users/\(uid)"
            
        }
    }
    
}

enum StorageRef {
    case root
    case profileImages
    
    func reference() -> StorageReference {
        switch self {
        case .root:
           return rootRef
        default:
           return rootRef.child(path)
        }
    }
    
    private var rootRef: StorageReference {
        return Storage.storage().reference()
    }
    
    private var path: String {
        switch self {
        case .root:
            return ""
        case .profileImages:
            return "profileImages"
        }
    }
    
}






