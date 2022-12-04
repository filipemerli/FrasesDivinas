//
//  Usuario.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 04/04/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import UIKit

class Usuario {
    var nomeUsuario: String
    let uid: String
    var nomeCompleto: String
    var email: String
    var imagemProfile: UIImage?

    init(uid: String, nomeUsuario: String, imagemProfile: UIImage, email: String, nomeCompleto: String) {
        self.uid = uid
        self.nomeUsuario = nomeUsuario
        self.imagemProfile = imagemProfile
        self.email = email
        self.nomeCompleto = nomeCompleto
    }

    func salvar(completion: @escaping (Error?) -> Void) {
        let ref = DatabaseRef.users(uid: uid).reference()
        ref.setValue(toDict())
        if let imagemProfile = self.imagemProfile {
            let firebaseImage = Image(image: imagemProfile)
            firebaseImage.saveProfileImage(email, { error in
                completion(error)
            })
        }
    }

    func toDict() -> [String : Any] {
        return [
            "uid" : uid,
            "nomeUsuario" : nomeUsuario,
            "nomeCompleto" : nomeCompleto,
            "email" : email,
        ]
    }
}
