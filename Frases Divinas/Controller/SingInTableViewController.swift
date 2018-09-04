//
//  SingInTableViewController.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 09/04/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import UIKit
import Firebase

class SingInTableViewController: UITableViewController {
    
    // MARK: Definicoes

    @IBOutlet weak var logarNovamenteButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var senhaTextField: UITextField!
    
    @IBAction func voltarPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logarNovamenteButton.layer.cornerRadius = 9
        emailTextField.delegate = self
        senhaTextField.delegate = self
    }
    
    // MARK: Logar
    
    @IBAction func signInPressed(_ sender: Any) {
        
        let email = emailTextField.text!.trimmingCharacters(in: .whitespaces)
        let senha = senhaTextField.text!
        
        guard email.count > 0 else {
            mostrarAlerta("Digite seu email.")
            return
        }
        guard senha.count > 0 else {
            mostrarAlerta("Digite sua senha.")
            return
        }
        if (emailTextField.text == nil || senhaTextField.text == nil) {
            mostrarAlerta("Complete os dados para continuar.")
        }else {
            let spinner = SingInTableViewController.displaySpinner(onView: self.view)
            let temInternet = Reachability.temConexaoDeInternet()
            if temInternet {
                DispatchQueue.main.async {
                    Auth.auth().signIn(withEmail: email, password: senha) { (user, error) in
                        if error == nil && user != nil {
                            SingInTableViewController.removeSpinner(spinner: spinner)
                            self.dismiss(animated: true, completion: nil)
                        }else {
                            if (error?.localizedDescription.contains("password"))! {
                                SingInTableViewController.removeSpinner(spinner: spinner)
                                self.esqueciSenhaAlert(email)
                            }else {
                                SingInTableViewController.removeSpinner(spinner: spinner)
                                self.recuperarSenhaEmail("Verifique os dados e tente novamente!")
                            }
                            SingInTableViewController.removeSpinner(spinner: spinner)
                        }
                    }
                }
            }else {
                SingInTableViewController.removeSpinner(spinner: spinner)
                mostrarAlerta("Sem conexão de internet")
            }
        }
    }
    
    // MARK: Alertas

    func esqueciSenhaAlert(_ email: String?) {
        let senhaAlert = UIAlertController(title: "Esqueceu a senha?", message: "Receber email de recuperação de senha.", preferredStyle: .alert)
        senhaAlert.addTextField { (textField:UITextField) in
            textField.placeholder = "Email:"
            textField.text = email
        }
        senhaAlert.addAction(UIAlertAction(title: "Não Esqueci!", style: .cancel, handler: nil))
        
        senhaAlert.addAction(UIAlertAction(title: "Enviar", style: .default, handler: { (action:UIAlertAction) in
            if let email = senhaAlert.textFields?.first?.text {
                Auth.auth().sendPasswordReset(withEmail: email, completion: { (error) in
                    if error != nil {
                        self.recuperarSenhaEmail("Email Errado!")
                    }else {
                        self.recuperarSenhaEmail("Email Enviado!")
                    }
                })
            }
        }))
        present(senhaAlert, animated: true, completion: nil)
    }
    
    func recuperarSenhaEmail(_ texto: String) {
        let emailErradoAlert = UIAlertController(title: "Alerta", message: texto, preferredStyle: .alert)
        emailErradoAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(emailErradoAlert, animated: true, completion: nil)
    }
    
    func mostrarAlerta(_ texto: String) {
        let oAlerta = UIAlertController(title: "Alerta", message: texto, preferredStyle: .alert)
        oAlerta.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(oAlerta, animated: true, completion: nil)
    }
    
}

// MARK: TextFields Delegate

extension SingInTableViewController: UITextFieldDelegate {    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}


