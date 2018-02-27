//
//  Frases.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 22/02/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import Foundation
import Firestore

protocol DocumentationSerializable {
    init?(dictionary:[String: Any])
}

struct Frase {
    var nome: String
    var conteudo: String
    var horaCriado: Date
    
    var dictionary:[String: Any] {
        return [
            "nome":nome,
            "conteudo":conteudo,
            "horaCriado":horaCriado
        ]
    }
}

extension Frase : DocumentationSerializable {
    init?(dictionary: [String : Any]) {
        guard let nome = dictionary["nome"] as? String,
            let conteudo = dictionary["conteudo"] as? String,
            let horaCriado = dictionary["horaCriado"] as? Date else {return nil}
        
        self.init(nome: nome, conteudo: conteudo, horaCriado: horaCriado)
    }
    
}
