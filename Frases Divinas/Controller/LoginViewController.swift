//
//  LoginViewController.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 09/04/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    // MARK: ViewDidAppear
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let temInternet = Reachability.temConexaoDeInternet()
        if temInternet == false {
            mostrarAlerta("Sem conexão de internet!\nLigue o Wi-Fi ou 'dados móveis'.")
        }
        DispatchQueue.main.async {
            Auth.auth().addStateDidChangeListener { (auth, user) in
                if user != nil {
                    self.dismiss(animated: false, completion: nil)
                } else {
                    debugPrint("Auth = \(String(describing: auth.debugDescription))")
                }
            }
        }
    }
    
    // MARK: Alerta
    
    func mostrarAlerta(_ texto: String) {
        let oAlerta = UIAlertController(title: "Alerta", message: texto, preferredStyle: .alert)
        oAlerta.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(oAlerta, animated: true, completion: nil)
    }


}
