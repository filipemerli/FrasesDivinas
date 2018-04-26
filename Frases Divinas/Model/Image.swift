//
//  Image.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 27/03/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import UIKit
import Firebase

class Image {
    var image: UIImage
    var downloadURL: URL?
    var ref: StorageReference!
    
    init(image: UIImage) {
        self.image = image
    }
    
    func saveProfileImage(_ userEmail: String, _ completion: @escaping (Error?) -> Void) {
        let imagemRedimensionada = image.resize()
        if let imageData = UIImageJPEGRepresentation(imagemRedimensionada, 0.5) {
            ref = StorageRef.profileImages.reference().child(userEmail)
            ref.putData(imageData, metadata: nil, completion: { (metaData, error) in
                completion(error)
            })
        }
    }
    
}

private extension UIImage {
    func resize() -> UIImage {
        let altura: CGFloat = 500.0
        let proporcao = self.size.width / self.size.height
        let largura = altura * proporcao
        
        let novoTamanho = CGSize(width: largura, height: altura)
        let novoRetangulo = CGRect(x: 0, y: 0, width: largura, height: altura)
        
        UIGraphicsBeginImageContext(novoTamanho)
        self.draw(in: novoRetangulo)
        let imagemRedimensionada = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return imagemRedimensionada!
        
    }
}











