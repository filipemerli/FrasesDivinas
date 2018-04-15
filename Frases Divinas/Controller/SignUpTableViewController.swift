//
//  SignUpTableViewController.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 08/04/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import UIKit
import Foundation
import Firebase

class SignUpTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imagemPerfil: UIImage!
    
    @IBOutlet weak var fotoPerfilView: UIImageView!
    
    @IBAction func mudarFotoPerfil(_ sender: Any) {
    
        let spinner = SignUpTableViewController.displaySpinner(onView: self.view)
        DispatchQueue.main.async {
            self.pegarImagemLibrary()
            SignUpTableViewController.removeSpinner(spinner: spinner)
        }
    }
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nomeCompletoTextField: UITextField!
    @IBOutlet weak var nomeUsuarioTextField: UITextField!
    @IBOutlet weak var criarSenhaTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        nomeCompletoTextField.delegate = self
        nomeUsuarioTextField.delegate = self
        criarSenhaTextField.delegate = self
    }
    
    @IBAction func criarNovaConta(_ sender: Any) {
        guard imagemPerfil != nil else{
            mostrarAlerta("Selecione um foto de perfil para continuar.")
            return
        }
        guard (criarSenhaTextField.text?.count)! >= 6 else {
            mostrarAlerta("Senha muito curta.")
            return
        }
        guard (nomeUsuarioTextField.text?.count)! >= 4 else {
            mostrarAlerta("Nome de Usuário muito curto.")
            return
        }
        let spinner = SingInTableViewController.displaySpinner(onView: self.view)
        if (emailTextField.text != "" && criarSenhaTextField.text != "" && nomeUsuarioTextField.text != "" && nomeCompletoTextField.text != "") {
            let nomeUsuario = nomeUsuarioTextField.text!
            let email = emailTextField.text!
            let senha = criarSenhaTextField.text!
            let nomeCompleto = nomeCompletoTextField.text!
            DispatchQueue.main.async {
                Auth.auth().createUser(withEmail: email, password: senha, completion: { (dbUser, error) in
                    if error != nil {
                        SingInTableViewController.removeSpinner(spinner: spinner)
                        self.mostrarAlerta("Erro ao criar usuário. Verifique seus dados e tente novamente!")
                    } else if let dbUser = dbUser {
                        let novoUsuario = Usuario(uid: dbUser.uid, nomeUsuario: nomeUsuario, imagemProfile: self.imagemPerfil, email: email, nomeCompleto: nomeCompleto)
                        novoUsuario.salvar(completion: { (error) in
                            if error != nil {
                                SingInTableViewController.removeSpinner(spinner: spinner)
                                self.mostrarAlerta("Erro ao salvar novo usuário. Verifique seus dados e tente novamente!")
                            }else {
                                Auth.auth().signIn(withEmail: email, password: senha, completion: { (dbUser, error) in
                                    if error != nil {
                                        SingInTableViewController.removeSpinner(spinner: spinner)
                                        self.mostrarAlerta("Erro ao logar com novo usuário. Verifique sua conexão com a internet e tente logar.")
                                    }else {
                                        SingInTableViewController.removeSpinner(spinner: spinner)
                                        self.dismiss(animated: true, completion: nil)
                                    }
                                })
                            }
                        })
                    }
                })
            }
        }else {
            SingInTableViewController.removeSpinner(spinner: spinner)
            mostrarAlerta("Dados incompletos!")
        }
    }
    
    @IBAction func voltarPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Alerta
    
    func mostrarAlerta(_ texto: String) {
        let oAlerta = UIAlertController(title: "Alerta", message: texto, preferredStyle: .alert)
        oAlerta.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(oAlerta, animated: true, completion: nil)
    }
    
    // MARK: ImagePicker
    
    func pegarImagemLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imagemPerfil = image
            fotoPerfilView.image = imagemPerfil
            fotoPerfilView.layer.cornerRadius = fotoPerfilView.bounds.width / 2.0
            fotoPerfilView.layer.masksToBounds = true
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }


}

// MARK: TextFields Delegate

extension SignUpTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}



