//
//  TableViewController.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 21/02/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import UIKit
import Firestore

class TableViewController: UITableViewController {
    
    var db: Firestore!
    var fraseArray = [Frase]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        db = Firestore.firestore()
        loadData()
        verificarUpdates()
    }
    
    func loadData() {
        db.collection("frases").getDocuments() {
            querySnapshot, error in
            if let error = error {
                print("\(error.localizedDescription)")
            } else {
                self.fraseArray = querySnapshot!.documents.flatMap({Frase(dictionary: $0.data())})
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    func verificarUpdates() {
        db.collection("frases").whereField("dataCriada", isGreaterThan: Date())
            .addSnapshotListener {
                querySnapshot, error in
                
                guard let snapshot = querySnapshot else {return}
                
                snapshot.documentChanges.forEach {
                    diff in
                    
                    if diff.type == .added {
                        self.fraseArray.append(Frase(dictionary: diff.document.data())!)
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                        }
                    }
                }
                
        }
    }
    
    @IBAction func novaFrase(_ sender: Any) {
        
        let composeAlert = UIAlertController(title: "Nova Frase", message: "Coloque seu nome e sua mensagem", preferredStyle: .alert)
        
        composeAlert.addTextField { (textField:UITextField) in
            textField.placeholder = "Seu nome"
        }
        
        composeAlert.addTextField { (textField:UITextField) in
            textField.placeholder = "Sua mensagem"
        }
        
        composeAlert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
        
        composeAlert.addAction(UIAlertAction(title: "Enviar", style: .default, handler: { (action:UIAlertAction) in

            if let nome = composeAlert.textFields?.first?.text, let conteudo = composeAlert.textFields?.last?.text {
                
                let novaFrase = Frase(nome: nome, conteudo: conteudo, dataCriada: Date())
                var referencia: DocumentReference? = nil
                referencia = self.db.collection("frases").addDocument(data: novaFrase.dictionary) {
                    error in
                    
                    if let error = error {
                        print("Erro ao adicionar documento: \(error.localizedDescription)")
                    } else {
                        print("Documento adicionado com o ID: \(referencia!.documentID)")
                    }
                }
            }
            
        }))
        
        self.present(composeAlert, animated: true, completion: nil)
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
        cell.textLabel?.text = "\(frase.nome): \(frase.conteudo)"
        cell.detailTextLabel?.text = "\(frase.dataCriada)"
        
        return cell
    }

}
