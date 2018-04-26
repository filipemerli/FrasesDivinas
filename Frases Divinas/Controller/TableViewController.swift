//
//  TableViewController.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 21/02/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import UIKit
import Firestore
import Firebase

class TableViewController: UITableViewController {
    
    
    //MARK: Definicoes
    
    var ref: StorageReference!
    var db: Firestore!
    var fraseArray = [Frase]()
    var uid: String?
    var nomeUsuario: String?
    var emailUsuario: String?
    var imageFromDb: Image?

    let atributosTituloTexto = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline), NSAttributedStringKey.foregroundColor: UIColor(red: 0.298, green: 0.259, blue: 1.0, alpha: 1.0)]
    let atributoPadrao: [NSAttributedStringKey: Any] = [
        NSAttributedStringKey.font: UIFont(name: "Optima-Italic", size: 20.0)!,
        NSAttributedStringKey.foregroundColor: UIColor(red: 0.298, green: 0.259, blue: 1.0, alpha: 1.0)
    ]
    
    //MARK: ViewDidiLoad e ViewDidAppear
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        loadData()
        verificarUpdates()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            Auth.auth().addStateDidChangeListener({ (auth, user) in
                if user != nil {
                    self.uid = (user?.uid)!
                    self.atualizarInfo()
                }else {
                    self.performSegue(withIdentifier: "ExibirLoginScreen", sender: nil)
                }
            })
        }
    }
    
    // MARK: Reload table cells
    
    func loadData() {
        let spinner = TableViewController.displaySpinner(onView: self.view)
        db.collection("frases").order(by: "dataCriada", descending: true).limit(to: 50).getDocuments() {
            querySnapshot, error in
            if error != nil {
                self.mostrarAlerta("Erro ao carregar dados da internet.\nTente novamente. (Sair e Logar novamente :()")
            } else {
                self.fraseArray = querySnapshot!.documents.compactMap({Frase(dictionary: $0.data())})
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    TableViewController.removeSpinner(spinner: spinner)
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
            debugPrint(error.localizedDescription)
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
            let composeAlert = UIAlertController(title: "Nova Frase", message: "Coloque sua mensagem", preferredStyle: .alert)
            composeAlert.addTextField { (textField:UITextField) in
                textField.placeholder = "Sua mensagem"
                textField.adjustsFontForContentSizeCategory = true
            }
            composeAlert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
            composeAlert.addAction(UIAlertAction(title: "Enviar", style: .default, handler: { (action:UIAlertAction) in
                guard let conteudo = composeAlert.textFields?.first?.text else {
                    return
                }
                if (conteudo.count > 1) && (conteudo.count < 101) {
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
                        }
                    }
                }else {
                    self.mostrarAlerta("Sua frase é muito longa ou muito curta!")
                }
            }))
            present(composeAlert, animated: true, completion: nil)
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
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let temInternet = Reachability.temConexaoDeInternet()
        if temInternet {
            let emailSelecionado = fraseArray[indexPath.row].email
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

        /*
        let msg = fraseArray[indexPath.row].conteudo
        let urlWhats = "whatsapp://send?text=\(msg)"
        if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let whatsappURL = NSURL(string: urlString) {
                if UIApplication.shared.canOpenURL(whatsappURL as URL){
                    UIApplication.shared.open(whatsappURL as URL, options: [:], completionHandler: nil)
                } else {
                    print("Error 03")
                }
            }else{
                print("Error 02")
            }
        } else {
            print("Error 01")
        }
        */
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
    
    
}
