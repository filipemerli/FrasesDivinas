//
//  TableViewController.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 21/02/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import UIKit
import Foundation
import Firestore
import Firebase

class TableViewController: UITableViewController {
    
    //MARK: Definicoes
    
    @IBOutlet var popUpView: UIView!
    @IBOutlet weak var novaFraseButton: UIBarButtonItem!
    @IBOutlet weak var novaFraseOkBtn: UIButton!
    @IBOutlet weak var novaFraseCAncelBtn: UIButton!
    @IBOutlet weak var novaFraseTextView: UITextView!
    @IBOutlet weak var logOutButton: UIBarButtonItem!
    var ref: StorageReference!
    var db: Firestore!
    var fraseArray = [Frase]()
    var uid: String?
    var nomeUsuario: String?
    var emailUsuario: String?
    var imageFromDb: Image?
    
    
    let atributoPadrao: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont(name: "Georgia-BoldItalic", size: 20.0)!,
        NSAttributedStringKey.foregroundColor: #colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 1)]
    
    //MARK: ViewDidiLoad e ViewDidAppear
    
    override func viewDidLoad() {
        super.viewDidLoad()
        db = Firestore.firestore()
        loadData()
        verificarUpdates()
        configNovaFrseView()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            Auth.auth().addStateDidChangeListener({ (auth, user) in
                if user != nil {
                    self.uid = (user?.uid)!
                    self.atualizarInfo()
                    self.loadData()
                }else {
                    self.performSegue(withIdentifier: "ExibirLoginScreen", sender: nil)
                }
            })
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
         super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let imagemBackGround = UIImage(named: "FrasesDivinasBGV3")
        let bgView = UIImageView(image: imagemBackGround)
        self.tableView.backgroundView = bgView
        bgView.contentMode = .scaleAspectFit
        bgView.alpha = 0.8
        subscribeToKeyboardNotifications()
    }

    
    // MARK: Reload table cells
    
    func loadData() {
       // let spinner = TableViewController.displaySpinner(onView: self.view)
        db.collection("frases").order(by: "dataCriada", descending: true).limit(to: 50).getDocuments() {
            querySnapshot, error in
            if error != nil {
                self.mostrarAlerta("Erro ao carregar dados da internet.\nTente novamente. (Sair e Logar novamente :()")
            } else {
                self.fraseArray = querySnapshot!.documents.compactMap({Frase(dictionary: $0.data())})
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    //TableViewController.removeSpinner(spinner: spinner)
                }
            }
        }
    }
    
    // MARK: Buscar informacoes do Usuario logado
    
    func atualizarInfo() {
        let ref = DatabaseRef.users(uid: uid!).reference()
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let username = value?["nomeUsuario"] as? String ?? ""
            self.nomeUsuario = username
            let userEmail = value?["email"] as? String ?? ""
            self.emailUsuario = userEmail
        }) { (error) in
            self.mostrarAlerta("Erro ao atualizar informações. Verifique a sua conexão em configurações e volte aqui =)")
            //debugPrint(error.localizedDescription)
        }
    }
    
    // MARK: Verificar novas frases
    
    func verificarUpdates() {
        db.collection("frases").whereField("dataCriada", isGreaterThan: Date())
            .addSnapshotListener {
                querySnapshot, error in
                guard let snapshot = querySnapshot else {return}
                snapshot.documentChanges.forEach {
                    diff in
                    if diff.type == .added {
                        self.fraseArray.insert((Frase(dictionary: diff.document.data())!), at: 0)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
        }
    }
    
    // MARK: Criar nova frase
    
    @IBAction func novaFrase(_ sender: Any) {
        let temInternet = Reachability.temConexaoDeInternet()
        if temInternet {
            novaFraseButton.isEnabled = false
            logOutButton.isEnabled = false
            tableView.allowsSelection = false
            tableView.alwaysBounceVertical = false
            let blurView = UIView()
            blurView.frame = self.view.frame
            blurView.backgroundColor = UIColor.gray
            blurView.tag = 2
            blurView.alpha = 0.5
            view.addSubview(blurView)
            popUpView.tag = 3
            view.addSubview(popUpView)
            popUpView.center = self.view.center
            popUpView.frame.origin.y -= 20
            novaFraseTextView.text = "Sua frase aqui!"

        } else {
            mostrarAlerta("Sem conexão com a internet.")
        }
    }
    
    //MARK: Log Out
    
    @IBAction func logOut(_ sender: Any) {
        let confirmar = UIAlertController(title: "Deseja mesmo sair?", message: "", preferredStyle: .alert)
        confirmar.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        confirmar.addAction(UIAlertAction(title: "Sair", style: .default, handler: { (sair) in
            try! Auth.auth().signOut()
            self.performSegue(withIdentifier: "ExibirLoginScreen", sender: nil)
        }))
        present(confirmar, animated: true, completion: nil)
        
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return fraseArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let frase = fraseArray[indexPath.row]
        let novoConteudo = NSMutableAttributedString(string: frase.conteudo, attributes: atributoPadrao)
        cell.textLabel?.attributedText = novoConteudo
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let dataFormatada = formatter.string(from: frase.dataCriada)
        formatter.dateFormat = "HH:mm"
        let horaFormatada = formatter.string(from: frase.dataCriada)
        cell.detailTextLabel?.text = "(criado \(dataFormatada) às \(horaFormatada)h) - \(frase.nome)"
        cell.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt linha: IndexPath) -> UISwipeActionsConfiguration? {
        if logOutButton.isEnabled {
            let compartilhar = UIContextualAction(style: .normal, title: "Zap", handler: {
                (action: UIContextualAction, view: UIView, success:(Bool) -> Void) in
                self.compartilharWhatsapp(linha: linha)
                success(true)
            })
            compartilhar.backgroundColor = UIColor(red: 0.145, green: 0.8275, blue: 0.4, alpha: 1.0)
            compartilhar.image = #imageLiteral(resourceName: "Zap30x30")
            let infoDoUser = UIContextualAction(style: .normal, title: "Info", handler: {
                (action: UIContextualAction, view: UIView, success:(Bool) -> Void) in
                self.infoDoUsuario(linha: linha)
            })
            infoDoUser.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
            infoDoUser.image = #imageLiteral(resourceName: "user_info30x30")
            let configuracao = UISwipeActionsConfiguration(actions: [compartilhar, infoDoUser])
            configuracao.performsFirstActionWithFullSwipe = false
            return configuracao
        }else {
            return UISwipeActionsConfiguration(actions: [])
        }
    }
    
    //MARK: Funcoes linhas da table
    
    func infoDoUsuario(linha: IndexPath) {
        let temInternet = Reachability.temConexaoDeInternet()
        if temInternet {
            let emailSelecionado = fraseArray[linha.row].email
            let opcoesAlerta = UIAlertController(title: "\n\n\n\nSobre o autor", message: "Usuário: \(emailSelecionado)", preferredStyle: .alert)
            
            opcoesAlerta.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(opcoesAlerta, animated: true) {
                let imageView = UIImageView(frame: CGRect(x: ((opcoesAlerta.view.frame.width / 2) - (75 / 2)) , y: 15, width: 75, height: 75))
                opcoesAlerta.view.addSubview(imageView)
                imageView.layer.cornerRadius = imageView.bounds.width / 2.0
                imageView.layer.masksToBounds = true
                
                let spinner = TableViewController.displaySpinner(onView: imageView)
                self.getProfileImage(emailSelecionado) { (url) in
                    if url != nil {
                        let task = URLSession.shared.dataTask(with: url!) { data, response, error in
                            guard let data = data, error == nil else { return }
                            DispatchQueue.main.async() {
                                let imagemPerfilpp = UIImage(data: data)
                                imageView.image = imagemPerfilpp
                                TableViewController.removeSpinner(spinner: spinner)
                            }
                        }
                        task.resume()
                    }else {
                        self.mostrarAlerta("Usuario com insformações incompletas.")
                    }
                }
                
            }
        } else {
            mostrarAlerta("Sem conexão com a internet.\nCertifique-se e tente novamente!")
        }
        
    }
    
    func compartilharWhatsapp(linha: IndexPath) {
        let msg = fraseArray[linha.row].conteudo
        let urlWhats = "whatsapp://send?text=\(msg)"
        if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let whatsappURL = NSURL(string: urlString) {
                if UIApplication.shared.canOpenURL(whatsappURL as URL){
                    UIApplication.shared.open(whatsappURL as URL, options: [:], completionHandler: nil)
                } else {
                    mostrarAlerta("Certifique-se de ter o app WhatsApp instalado em seu iPhone.")
                }
            }else{
                mostrarAlerta("Certifique-se de ter o app WhatsApp instalado em seu iPhone.")
            }
        } else {
            mostrarAlerta("Certifique-se de ter o app WhatsApp instalado em seu iPhone.")
        }
    }
    
    
    // MARK: Alertas
    
    func mostrarAlerta(_ texto: String) {
        let oAlerta = UIAlertController(title: "Alerta", message: texto, preferredStyle: .alert)
        oAlerta.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(oAlerta, animated: true, completion: nil)
    }
    
    func getProfileImage(_ userEmail: String, completion: @escaping (URL?) -> Void){
        ref = StorageRef.profileImages.reference().child(userEmail)
        ref.downloadURL { (url, error) in
            if error != nil {
                completion(nil)
            }else {
                completion(url)
            }
        }
    }
    
    
    //MARK: PopUp View Functions

    @IBAction func dismissPopUp(_ sender: Any) {
        dismissPopUpView()
    }
    
    func configNovaFrseView() {
        popUpView.clipsToBounds = true
        popUpView.layer.cornerRadius = 18
        novaFraseTextView.clipsToBounds = true
        novaFraseTextView.layer.cornerRadius = 12
    }
    
    @IBAction func uparNovaFrase(_ sender: Any) {
        let temInternet = Reachability.temConexaoDeInternet()
        if temInternet {
            let conteudo = novaFraseTextView.text!
            if (conteudo.count > 4) && (conteudo.count < 101) {
                let spinner = TableViewController.displaySpinner(onView: self.view)
                let novaFrase = Frase(nome: self.nomeUsuario!, conteudo: conteudo, dataCriada: Date(), email: self.emailUsuario!)
                var referencia: DocumentReference? = nil
                referencia = self.db.collection("frases").addDocument(data: novaFrase.dictionary) {
                    error in
                    if error != nil {
                        TableViewController.removeSpinner(spinner: spinner)
                        self.mostrarAlerta("Erro ao criar nova frase. Verifique sua conexão com a internet!")
                    } else {
                        TableViewController.removeSpinner(spinner: spinner)
                        self.dismissPopUpView()
                    }
                }
            }else {
                self.mostrarAlerta("Sua frase é muito longa ou muito curta!")
            }
        }
        
    }
    
    func dismissPopUpView() {
        novaFraseTextView.text.removeAll()
        for views in self.view.subviews {
            if (views.tag >= 2) {
                views.removeFromSuperview()
            }
        }
        novaFraseButton.isEnabled = true
        logOutButton.isEnabled = true
        tableView.allowsSelection = true
        tableView.alwaysBounceVertical = true
    }
}


// MARK: Teclado

extension TableViewController: UINavigationControllerDelegate {
    
    @objc func keyboardWillShow(_ notification:Notification) {
        popUpView.frame.origin.y = 15.0
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func subscribeToKeyboardNotifications() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
    }
    
    func unsubscribeFromKeyboardNotifications() {
        
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        popUpView.center = self.view.center
        popUpView.frame.origin.y -= 20
    }
}











