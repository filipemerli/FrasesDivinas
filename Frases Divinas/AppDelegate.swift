//
//  AppDelegate.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 21/02/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import UIKit
import Firebase
import Firestore


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func verificarFirstLaunch() {
        if(UserDefaults.standard.bool(forKey: "jaFoiFirstLaunch")) {
            //Nada por enquanto
        } else {
            UserDefaults.standard.set(true, forKey: "jaFoiFirstLaunch")
            UserDefaults.standard.set(false, forKey: "userPermiteFotos")
            UserDefaults.standard.set(false, forKey: "userJaClicouMudarFoto")
            UserDefaults.standard.set(false, forKey: "logarAnonimamente")
            UserDefaults.standard.set(0, forKey: "filtro")
            UserDefaults.standard.synchronize()
        }
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        verificarFirstLaunch()
        return true
    }

}

