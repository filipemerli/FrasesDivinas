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
import Photos

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
    
    @IBOutlet weak var criarNovaContaButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nomeCompletoTextField: UITextField!
    @IBOutlet weak var nomeUsuarioTextField: UITextField!
    @IBOutlet weak var criarSenhaTextField: UITextField!
    
    let textoFoto = "Nenhuma foto de perfil foi selecionada. Usar uma foto padrão?"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        criarNovaContaButton.layer.cornerRadius = 9
        emailTextField.delegate = self
        nomeCompletoTextField.delegate = self
        nomeUsuarioTextField.delegate = self
        criarSenhaTextField.delegate = self
        self.modalPresentationStyle = .fullScreen
    }
    
    @IBAction func criarNovaConta(_ sender: Any) {
        
        if imagemPerfil == nil {
            if ((UserDefaults.standard.bool(forKey: "userJaClicouMudarFoto") == true) && (UserDefaults.standard.bool(forKey: "userPermiteFotos") == false)) {
                alertaUsandoFotoPadrao()
            } else {
                alertaDeFoto()
            }
        }else {
            criarContaSim()
        }
    }
    
    func criarContaSim() {
        guard (criarSenhaTextField.text?.count)! >= 6 else {
            mostrarAlerta("Senha muito curta.")
            return
        }
        guard (nomeUsuarioTextField.text?.count)! >= 4 else {
            mostrarAlerta("Nome de Usuário muito curto.")
            return
        }
        guard (nomeCompletoTextField.text?.count)! > 0 else {
            mostrarAlerta("Faltou o seu nome... xD")
            return
        }
        let spinner = SingInTableViewController.displaySpinner(onView: self.view)
        if (emailTextField.text != "" && criarSenhaTextField.text != "" && nomeUsuarioTextField.text != "" && nomeCompletoTextField.text != "") {
            let nomeUsuario = nomeUsuarioTextField.text!
            let email = emailTextField.text!.trimmingCharacters(in: .whitespaces)
            let senha = criarSenhaTextField.text!
            let nomeCompleto = nomeCompletoTextField.text!
            DispatchQueue.main.async {
                Auth.auth().createUser(withEmail: email, password: senha, completion: { (dbUser, error) in
                    if error != nil {
                        if (error?.localizedDescription.contains("another account"))! {
                            SingInTableViewController.removeSpinner(spinner: spinner)
                            self.mostrarAlerta("Conta de email já cadastrada!")
                        } else {
                            SingInTableViewController.removeSpinner(spinner: spinner)
                            self.mostrarAlerta("Erro ao criar usuário. Verifique seus dados e tente novamente!")
                        }
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
                                        UserDefaults.standard.set(false, forKey: "logarAnonimamente")
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
    
    // MARK: Alertas
    
    func mostrarAlerta(_ texto: String) {
        let oAlerta = UIAlertController(title: "Alerta", message: texto, preferredStyle: .alert)
        oAlerta.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(oAlerta, animated: true, completion: nil)
    }
    
    func alertaDeFoto() {
        let oAlerta = UIAlertController(title: "Alerta", message: textoFoto, preferredStyle: .alert)
        oAlerta.addAction(UIAlertAction(title: "Vou mudar", style: .cancel, handler: nil))
        oAlerta.addAction(UIAlertAction(title: "Usar padrão", style: .default, handler: { (_ ) in
            self.imagemPerfil = #imageLiteral(resourceName: "icon_profile_big")
            self.fotoPerfilView.image = self.imagemPerfil
            self.criarContaSim()
        }))
        present(oAlerta, animated: true, completion: nil)
    }
    
    func alertaUsandoFotoPadrao() {
        let oAlerta = UIAlertController(title: "Aviso", message: "Usando foto padrão para o seu perfil", preferredStyle: .alert)
        oAlerta.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_ ) in
            self.imagemPerfil = #imageLiteral(resourceName: "icon_profile_big")
            self.fotoPerfilView.image = self.imagemPerfil
            self.criarContaSim()
        }))
        present(oAlerta, animated: true, completion: nil)
    }
    
    func alertaDeAjudaFotos() {
        let oAlerta = UIAlertController(title: "Ajuda", message: "Para permitir acesso a sua biblioteca de fotos feche este app, vá em Ajustes > Privacidade > Fotos > Frases Divinas e permita Leitura e Gravação.", preferredStyle: .alert)
        oAlerta.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(oAlerta, animated: true, completion: nil)
    }
    
    
    // MARK: ImagePicker
    
    func pegarImagemLibrary() {
        let spinner = SingInTableViewController.displaySpinner(onView: self.view)
        verificarPermissao(completion: { (permitido) in
            if permitido {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.allowsEditing = true
                imagePicker.sourceType = .photoLibrary
                SingInTableViewController.removeSpinner(spinner: spinner)
                self.present(imagePicker, animated: true, completion: nil)
            } else {
                SingInTableViewController.removeSpinner(spinner: spinner)
                if UserDefaults.standard.bool(forKey: "userJaClicouMudarFoto") {
                    self.alertaDeAjudaFotos()
                }
            }
            UserDefaults.standard.set(true, forKey: "userJaClicouMudarFoto")
        })
        
    }
    
    @objc func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.editedImage)] as? UIImage {
            imagemPerfil = image
            fotoPerfilView.image = imagemPerfil
            fotoPerfilView.layer.cornerRadius = fotoPerfilView.bounds.width / 2.0
            fotoPerfilView.layer.masksToBounds = true
        } else if let image = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
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
    
    // MARK: Verificar permissao da PhotoLibrary
    
    func verificarPermissao(completion:@escaping (Bool)->Void) {
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization({ (status) in
                if status == .authorized {
                    DispatchQueue.main.async(execute: {
                        UserDefaults.standard.set(true, forKey: "userPermiteFotos")
                        completion(true)
                    })
                } else {
                    UserDefaults.standard.set(false, forKey: "userPermiteFotos")
                    DispatchQueue.main.async(execute: {
                        completion(false)
                    })
                }
            })
        } else {
            DispatchQueue.main.async(execute: {
                UserDefaults.standard.set(true, forKey: "userPermiteFotos")
                completion(true)
            })
        }
    }
}

// MARK: TextFields Delegate

extension SignUpTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}




// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
