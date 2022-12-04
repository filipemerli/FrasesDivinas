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

    // MARK: Buttons
    
    //static let showLoginVC = "ExibirLoginScreen"
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var criarContaButton: UIButton!
    let serialQueue = DispatchQueue.init(label: "serialQueue")
    
    // MARK: ViewDidAppear
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UserDefaults.standard.set(false, forKey: "logarAnonimamente")
        let temInternet = Reachability.temConexaoDeInternet()
        if temInternet == false {
            mostrarAlerta("Sem conexão de internet!\nLigue o Wi-Fi ou 'dados móveis' e tente novamente.")
        } else {
            serialQueue.async {
                Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
                    if user != nil {
                        self?.dismiss(animated: false, completion: nil)
                    } 
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

    // MARK: Utilizar app sem conta
    
    @IBAction func utilizarSemConta(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "logarAnonimamente")
        dismiss(animated: true, completion: nil)
    }
    
}
