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

final class TableViewController: UITableViewController {

    //MARK: Definicoes

    @IBOutlet var popUpView: UIView!
    @IBOutlet weak var novaFraseOkBtn: UIButton!
    @IBOutlet weak var novaFraseCAncelBtn: UIButton!
    @IBOutlet weak var novaFraseTextView: UITextView!
    @IBOutlet weak var logOutButton: UIBarButtonItem!
    @IBOutlet weak var listaTextField: UITextField!
    @IBOutlet weak var filtroBtn: UIBarButtonItem!
    var ref: StorageReference!
    var db: Firestore!
    var fraseArray = [Frase]()
    var uid: String?
    var nomeUsuario: String?
    var emailUsuario: String?
    var nomeCompleto: String?
    var imageFromDb: Image?
    var comecouEscrever = false
    var roundButton = UIButton()
    let listaPicker = UIPickerView()
    let categs = ["religiosas","músicas", "motivação", "poema", "autoral"]
    var categariaAtual = "divinas"
    var filtro = UserDefaults.standard.integer(forKey: "filtro")
    var tabela = [Int]()
    var frasesFiltra = [Frase]()
    private var isLoggedIn = false

    let atributoPadrao: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.font: UIFont(name: "Georgia-BoldItalic", size: 20.0)!,
        NSAttributedString.Key.foregroundColor: #colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 1)]

    //MARK: ViewDidiLoad e ViewDidAppear

    override func viewDidLoad() {
        super.viewDidLoad()
        filtro = UserDefaults.standard.integer(forKey: "filtro")
        refreshControl?.addTarget(self, action: #selector(recarregar), for: UIControl.Event.valueChanged)
        roundButton = UIButton(type: .custom)
        roundButton.setTitleColor(UIColor.orange, for: .normal)
        roundButton.addTarget(self, action: #selector(novaFrase(_:)), for: UIControl.Event.touchUpInside)
        novaFraseTextView.delegate = self
        listaPicker.delegate = self
        listaPicker.dataSource = self
        listaTextField.inputView = listaPicker
        configTableView()
        db = Firestore.firestore()
        verificarUpdates()
        tableView.addSubview(roundButton)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Auth.auth().addStateDidChangeListener({ [weak self] (auth, user) in
            if user != nil {
                self?.isLoggedIn = true
                self?.logOutButton.title = "Sair"
                self?.uid = (user?.uid)!
                self?.atualizarInfo()
                self?.loadData()
            } else {
                if UserDefaults.standard.bool(forKey: "logarAnonimamente") {
                    self?.loadData()
                    self?.logOutButton.title = "Voltar"
                } else {
                    self?.performSegue(withIdentifier: "ExibirLoginScreen", sender: nil)
                }
            }
        })
     }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        subscribeToKeyboardNotifications()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        roundButton.layer.cornerRadius = roundButton.layer.frame.size.width / 2
        roundButton.clipsToBounds = true
        roundButton.setImage(UIImage(named: "mais"), for: .normal)
        roundButton.translatesAutoresizingMaskIntoConstraints = false
        roundButton.alpha = 0.90
        let addToView: UIView = view.superview ?? self.view
        NSLayoutConstraint.activate([
            roundButton.trailingAnchor.constraint(equalTo: addToView.trailingAnchor, constant: -35),
            roundButton.bottomAnchor.constraint(equalTo: addToView.bottomAnchor, constant: -35),
            roundButton.widthAnchor.constraint(equalToConstant: 55),
            roundButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }

    private func configTableView() {
        let imagemBackGround = UIImage(named: "FrasesDivinasBGV3")
        let bgView = UIImageView(image: imagemBackGround)
        self.tableView.backgroundView = bgView
        bgView.contentMode = .scaleAspectFit
        bgView.alpha = 0.8
    }

    private func configNovaFrseView() {
        popUpView.clipsToBounds = true
        popUpView.layer.cornerRadius = 18
        novaFraseTextView.clipsToBounds = true
        novaFraseTextView.layer.cornerRadius = 12
        novaFraseTextView.tag = 8
        listaTextField.placeholder = "selecione"
    }

    // MARK: Reload table cells

    private func loadData() {
        let spinner = TableViewController.displayWhiteSpin(naView: self.view)
        filtroBtn.isEnabled = false
        db.collection("frases").order(by: "dataCriada", descending: true).limit(to: 40).getDocuments() {
            querySnapshot, error in
            if error != nil {
                self.refreshControl?.endRefreshing()
                TableViewController.removeSpinner(spinner: spinner)
                self.mostrarAlerta("Erro ao carregar dados da internet.\nTente novamente. (Sair e Logar novamente 🙁)")
            } else {
                self.fraseArray = querySnapshot!.documents.compactMap({Frase(dictionary: $0.data())})
                DispatchQueue.main.async {
                    self.criarFiltros(filtro: self.filtro)
                    self.refreshControl?.endRefreshing()
                    self.filtroBtn.isEnabled = true
                    TableViewController.removeSpinner(spinner: spinner)
                }
            }
        }
    }

    // MARK: Buscar informacoes do Usuario logado

    private func atualizarInfo() {
        let ref = DatabaseRef.users(uid: uid!).reference()
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let username = value?["nomeUsuario"] as? String ?? ""
            self.nomeUsuario = username
            let userEmail = value?["email"] as? String ?? ""
            self.emailUsuario = userEmail
            let nomeCompleto = value?["nomeCompleto"] as? String ?? ""
            self.nomeCompleto = nomeCompleto
        }) { (error) in
            self.mostrarAlerta("Erro ao atualizar informações. Verifique a sua conexão em configurações e volte aqui =)")
        }
    }

    // MARK: Verificar novas frases

    private func verificarUpdates() {
        db.collection("frases").whereField("dataCriada", isGreaterThan: Date())
            .addSnapshotListener {
                querySnapshot, error in
                guard let snapshot = querySnapshot else {return}
                snapshot.documentChanges.forEach {
                    diff in
                    if diff.type == .added {
                        self.fraseArray.insert((Frase(dictionary: diff.document.data())!), at: 0)
                        DispatchQueue.main.async {
                            self.criarFiltros(filtro: self.filtro)
                        }
                    }
                    if diff.type == .removed {
                        self.loadData()
                    }
                }
            }
    }

    // MARK: Criar nova frase

    @objc private func novaFrase(_ sender: Any) {
        if UserDefaults.standard.bool(forKey: "logarAnonimamente") {
            alertaSemLogin()
        } else {
            if Reachability.temConexaoDeInternet() {
                if tabela.count != .zero {
                    self.tableView.scrollToRow(at: [0,0], at: .top, animated: false)
                }
                configNovaFrseView()
                logOutButton.isEnabled = false
                filtroBtn.isEnabled = false
                tableView.allowsSelection = false
                tableView.alwaysBounceVertical = false
                tableView.isScrollEnabled = false
                let blurView = UIView()
                blurView.frame = view.frame
                blurView.backgroundColor = UIColor.gray
                blurView.tag = 2
                blurView.alpha = 0.5
                view.addSubview(blurView)
                popUpView.tag = 3
                view.addSubview(popUpView)
                popUpView.center = view.center
                popUpView.frame.origin.y -= 50
                novaFraseTextView.text = "Sua frase aqui!"
            } else {
                mostrarAlerta("Sem conexão com a internet.")
            }
        }
    }

    // MARK: Log Out

    @IBAction private func logOut(_ sender: Any) {
        guard isLoggedIn == true else {
            logOutAction()
            return
        }
        let confirmar = UIAlertController(title: "Deseja mesmo sair?", message: "", preferredStyle: .alert)
        confirmar.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        confirmar.addAction(UIAlertAction(title: "Sair", style: .destructive, handler: { _ in
            self.logOutAction()
        }))
        present(confirmar, animated: true, completion: nil)
    }

    private func logOutAction() {
        do {
            try Auth.auth().signOut()
        } catch {
            return
        }
        UserDefaults.standard.set(false, forKey: "logarAnonimamente")
        self.performSegue(withIdentifier: "ExibirLoginScreen", sender: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return frasesFiltra.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let frase = frasesFiltra[indexPath.row]
        let novoConteudo = NSMutableAttributedString(string: frase.conteudo, attributes: atributoPadrao)
        cell.textLabel?.attributedText = novoConteudo
        cell.detailTextLabel?.text = "\(frase.categoria) - \(frase.nome)"
        cell.backgroundColor = UIColor(white: 1.0, alpha: 0.1)
        //FOR FUTURE USE
        //let acessorio = UIImageView(frame: CGRect(x: 0 , y: 0, width: 30, height: 30))
        //acessorio.image = UIImage(named:"userPDF")
        //cell.accessoryView = acessorio
        return cell
    }

    // MARK: Swipe Actions

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt linha: IndexPath) -> UISwipeActionsConfiguration? {
        if logOutButton.isEnabled {
            let compartilhar = UIContextualAction(style: .normal, title: "", handler: {
                (action: UIContextualAction, view: UIView, success:(Bool) -> Void) in
                self.compartilharWhatsapp(linha: (self.tabela[linha.row] - 1))
                success(true)
            })
            compartilhar.image = UIImage(named: "compartilhar")
            compartilhar.backgroundColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: .zero)
            let infoDoUser = UIContextualAction(style: .normal, title: "", handler: {
                (action: UIContextualAction, view: UIView, success:(Bool) -> Void) in
                self.infoDoUsuario(linha: (self.tabela[linha.row] - 1))
            })
            infoDoUser.image = #imageLiteral(resourceName: "userPDF")
            infoDoUser.backgroundColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: .zero)
            let configuracao = UISwipeActionsConfiguration(actions: [compartilhar, infoDoUser])
            configuracao.performsFirstActionWithFullSwipe = false
            return configuracao
        } else {
            return UISwipeActionsConfiguration(actions: [])
        }
    }

    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt linha: IndexPath) -> UISwipeActionsConfiguration? {
        if logOutButton.isEnabled {
            let dedurar = UIContextualAction(style: .normal, title: "", handler: {
                (action: UIContextualAction, view: UIView, success:(Bool) -> Void) in
                let confirmar = UIAlertController(title: "Deseja mesmo denunciar esta frase?", message: "", preferredStyle: .alert)
                confirmar.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
                confirmar.addAction(UIAlertAction(title: "Sim", style: .default, handler: { (sair) in
                    let frase = self.fraseArray[(self.tabela[linha.row] - 1)]
                    self.fazerDenuncia(frase: frase)
                }))
                self.present(confirmar, animated: true, completion: nil)
            })
            dedurar.backgroundColor = UIColor.init(red: 1, green: 1, blue: 1, alpha: .zero)
            dedurar.image = UIImage(named: "denunciar")
            let denucia = UISwipeActionsConfiguration(actions: [dedurar])
            denucia.performsFirstActionWithFullSwipe = false
            return denucia
        } else {
            return UISwipeActionsConfiguration(actions: [])
        }
    }

    //MARK: Funcoes linhas da table

    private func infoDoUsuario(linha: Int) {
        let temInternet = Reachability.temConexaoDeInternet()
        if temInternet {
            let nomeSelecionado = fraseArray[linha].nome
            let emailSelecionado = fraseArray[linha].email
            let opcoesAlerta = UIAlertController(title: "\n\n\n\nSobre o autor", message: "Usuário: \(nomeSelecionado)", preferredStyle: .alert)
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
                    } else {
                        self.mostrarAlerta("Usuario com insformações incompletas.")
                    }
                }
            }
        } else {
            mostrarAlerta("Sem conexão com a internet.\nCertifique-se e tente novamente!")
        }
    }

    // MARK: Comprtilhar via Whatss

    private func compartilharWhatsapp(linha: Int) {
        let msg = fraseArray[linha].conteudo
        let urlWhats = "whatsapp://send?text=\(msg)"
        if let urlString = urlWhats.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            if let whatsappURL = NSURL(string: urlString) {
                if UIApplication.shared.canOpenURL(whatsappURL as URL) {
                    UIApplication.shared.open(whatsappURL as URL, options: convertToUIApplicationOpenExternalURLOptionsKeyDictionary([:]), completionHandler: nil)
                } else {
                    semWhats(texto: msg)
                }
            } else {
                semWhats(texto: msg)
            }
        } else {
            semWhats(texto: msg)
        }
    }
    
    private func semWhats(texto: String) {
        let enviarTexto = [texto]
        let activityVC = UIActivityViewController(activityItems: enviarTexto, applicationActivities: nil)
        activityVC.popoverPresentationController?.sourceView = self.view
        activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop]
        self.present(activityVC, animated: true, completion: nil)
    }
    
    // MARK: Filtro

    private func alertaFiltros() {
        let titulos = ["Todas", "Divinas", "Músicas", "Motivação", "Poema", "Autoral"]

        let alerta = UIAlertController(title: "Filtrar por:", message: nil, preferredStyle: .actionSheet)

        titulos.enumerated().forEach { (index, titulo) in
            alerta.addAction(UIAlertAction(title: titulo, style: .default, handler: { action in
                self.filtro = index
                UserDefaults.standard.set(index, forKey: "filtro")
                self.criarFiltros(filtro: index)
            }))
        }

        alerta.addAction(UIAlertAction(title: "Cancelar", style: .destructive, handler: nil))
        present(alerta, animated: true) {
            alerta.actions[self.filtro].isEnabled = false
        }
    }

    // MARK: Alertas

    private func mostrarAlerta(_ texto: String) {
        let oAlerta = UIAlertController(title: "Alerta", message: texto, preferredStyle: .alert)
        oAlerta.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(oAlerta, animated: true, completion: nil)
    }

    private func getProfileImage(_ userEmail: String, completion: @escaping (URL?) -> Void) {
        ref = StorageRef.profileImages.reference().child(userEmail)
        ref.downloadURL { (url, error) in
            if error != nil {
                completion(nil)
            } else {
                completion(url)
            }
        }
    }

    private func alertaSemLogin() {
        let oAlerta = UIAlertController(title: "Aviso", message: "Você deve criar uma conta para Criar Nova Frase", preferredStyle: .alert)
        oAlerta.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(oAlerta, animated: true, completion: nil)
    }

    //MARK: PopUp View Functions

    @IBAction private func dismissPopUp(_ sender: Any) {
        dismissPopUpView()
    }

    @IBAction private func uparNovaFrase(_ sender: Any) {
        if comecouEscrever {
            let temInternet = Reachability.temConexaoDeInternet()
            if temInternet {
                let categoria = listaTextField?.text ?? ""
                if categs.contains(categoria) {
                    let conteudo = novaFraseTextView.text!.trimmingCharacters(in: .whitespacesAndNewlines)
                    if (conteudo.count > 4) && (conteudo.count < 141) {
                        let spinner = TableViewController.displaySpinner(onView: self.view)
                        let novaFrase = Frase(nome: self.nomeUsuario!, conteudo: conteudo, dataCriada: Date(), email: self.emailUsuario!, upVotes: 0, denunciada: false, categoria: categoria)
                        _ = self.db.collection("frases").addDocument(data: novaFrase.dictionary) {
                            error in
                            if error != nil {
                                TableViewController.removeSpinner(spinner: spinner)
                                self.mostrarAlerta("Erro ao criar nova frase. Verifique sua conexão com a internet!")
                            } else {
                                TableViewController.removeSpinner(spinner: spinner)
                                self.dismissPopUpView()
                            }
                        }
                    } else {
                        self.mostrarAlerta("Sua frase é muito curta ou muito longa!")
                    }
                } else {
                    self.mostrarAlerta("Selecione uma categoria para sua frase!")
                }
            } else {
                self.mostrarAlerta("Sem conexão com a internet.\nCertifique-se e tente novamente!")
            }
        } else {
            mostrarAlerta("Por favor escreva uma frase.")
        }
    }
    
    private func fazerDenuncia(frase: Frase) {
        DispatchQueue.main.async {
            if Reachability.temConexaoDeInternet() {
                let spinner = TableViewController.displaySpinner(onView: self.view)
                self.db.collection("frases").whereField("conteudo", isEqualTo: frase.conteudo)
                    .getDocuments() { (querySnapshot, err) in
                        if err != nil {
                            TableViewController.removeSpinner(spinner: spinner)
                            self.mostrarAlerta("Erro na cominucação com o servidor. Verifique sua conexão e tente novamente.")
                        } else if frase.denunciada == true {
                            TableViewController.removeSpinner(spinner: spinner)
                            self.mostrarAlerta("Frase já denunciada. Agradecemos a colaboração =D")
                        } else {
                            for document in querySnapshot!.documents {
                                self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                                    transaction.updateData(["denunciada": true], forDocument: document.reference)
                                }, completion: { (object, error) in
                                    if error != nil {
                                        self.mostrarAlerta("Erro ao denunciar frase. Talvez sua conexão tenha falhado. Tente novamente.")
                                    } else{
                                        self.mostrarAlerta("Frase denunciada!\nNossa equipe tomará as medidas necessárias ;)")
                                    }
                                })
                            }
                            TableViewController.removeSpinner(spinner: spinner)
                        }
                }
            } else {
                self.mostrarAlerta("Verifique sua conexão com a internet e tente novamente.")
            }
        }
    }
 
    private func dismissPopUpView() {
        novaFraseTextView.text.removeAll()
        for views in self.view.subviews {
            if (views.tag >= 2) {
                views.removeFromSuperview()
            }
        }
        logOutButton.isEnabled = true
        filtroBtn.isEnabled = true
        comecouEscrever = false
        tableView.allowsSelection = true
        tableView.alwaysBounceVertical = true
        tableView.isScrollEnabled = true
    }

    @IBAction private func filtrar(_ sender: Any) {
        alertaFiltros()
    }

    @objc private func recarregar(){
        refreshControl?.endRefreshing()
        let temNet = Reachability.temConexaoDeInternet()
        if temNet {
            loadData()
        } else {
            mostrarAlerta("Falha ao atualizar. Verifique sua conexão com a internet.")
        }
    }
    
    private func criarFiltros(filtro: Int){
        tabela.removeAll()
        frasesFiltra.removeAll()
        if filtro != 0 {
            var cnt = 1
            for frase in fraseArray {
                if frase.categoria == categs[(filtro - 1)] {
                    frasesFiltra.insert(frase, at: frasesFiltra.endIndex)
                    tabela.insert(cnt, at: tabela.endIndex)
                }
                cnt += 1
            }
        } else{
            frasesFiltra = fraseArray
            let indice = frasesFiltra.count
            for index in 1...indice {
                tabela.insert(index, at: tabela.endIndex)
            }
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
            if self.tabela.count == 0 {
                self.mostrarAlerta("Nenhuma frase da categoria \(self.categs[(filtro - 1)]) foi criada recentemente.\nCrie uma, aproveite 😇")
            }
        }
    }
    
}

// MARK: Teclado

extension TableViewController: UINavigationControllerDelegate {

    @objc func keyboardWillShow(_ notification: Notification) {
        popUpView.frame.origin.y = 15.0
    }

    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue

        return keyboardSize?.cgRectValue.height ?? .zero
    }

    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    @objc func keyboardWillHide(_ notification:Notification) {
        popUpView.center = self.view.center
        popUpView.frame.origin.y -= 20
    }
}

extension TableViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.tag == 8 {
            if novaFraseTextView.text == "Sua frase aqui!" {
                novaFraseTextView.text = ""
            }
            comecouEscrever = true
        }
    }
}

// MARK: PickerView

extension TableViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {

        return 1
    }
    
    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {

        return categs.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {

        return categs[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        categariaAtual = categs[row]
        listaTextField.text = categs[row]
    }
}


// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUIApplicationOpenExternalURLOptionsKeyDictionary(_ input: [String: Any]) -> [UIApplication.OpenExternalURLOptionsKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (UIApplication.OpenExternalURLOptionsKey(rawValue: key), value)})
}
