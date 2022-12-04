//
//  Frase.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 28/02/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import Foundation
import Firestore

protocol DocmentSerializable {
    init?(dictionary: [String: Any])
}

struct Frase {
    var nome: String
    var conteudo: String
    var dataCriada: Date
    var email: String
    var upVotes: Int
    var denunciada: Bool
    var categoria: String

    var dictionary: [String: Any] {
        return [
            "nome": nome,
            "conteudo": conteudo,
            "dataCriada": dataCriada,
            "email": email,
            "upVotes": upVotes,
            "denunciada": denunciada,
            "categoria": categoria
        ]
    }
}

extension Frase : DocmentSerializable {
    init?(dictionary: [String: Any]) {
        guard let nome = dictionary["nome"] as? String,
            let conteudo = dictionary["conteudo"] as? String,
            let dataCriada = dictionary["dataCriada"] as? Date,
            let email = dictionary["email"] as? String,
            let upVotes = dictionary["upVotes"] as? Int,
            let denunciada = dictionary["denunciada"] as? Bool,
            let categoria = dictionary["categoria"] as? String else {
                return nil
        }
        self.init(nome: nome, conteudo: conteudo, dataCriada: dataCriada, email: email, upVotes: upVotes, denunciada: denunciada, categoria: categoria)
    }
}
