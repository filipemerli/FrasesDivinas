//
//  TableViewController.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 21/02/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func novaFrase(_ sender: Any) {
        
        let composeAlert = UIAlertController(title: "New Sweet", message: "Enter your name and message", preferredStyle: .alert)
        
        composeAlert.addTextField { (textField:UITextField) in
            textField.placeholder = "Your name"
        }
        
        composeAlert.addTextField { (textField:UITextField) in
            textField.placeholder = "Your message"
        }
        
        composeAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        composeAlert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (action:UIAlertAction) in
            
            // INTERESTING PART
            
        }))
        
        self.present(composeAlert, animated: true, completion: nil)
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.textLabel?.text = "Hello World"
        
        return cell
    }

}
