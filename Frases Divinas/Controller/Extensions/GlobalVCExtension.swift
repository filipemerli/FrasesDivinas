//
//  GlobalVCExtension.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 13/04/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import UIKit

extension UIViewController {
    
    class func displaySpinner(onView: UIView) -> UIView {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.4)
        let activIndic: UIActivityIndicatorView = .init(style: .large)
        activIndic.startAnimating()
        activIndic.center = spinnerView.center
        DispatchQueue.main.async {
            spinnerView.addSubview(activIndic)
            onView.addSubview(spinnerView)
        }
        return spinnerView
    }

    class func displayWhiteSpin(naView: UIView) -> UIView {
        let whiteSpiView = UIView.init(frame: naView.bounds)
        whiteSpiView.backgroundColor = UIColor.init(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        let indicador: UIActivityIndicatorView = .init(style: .medium)
        indicador.startAnimating()
        indicador.center = whiteSpiView.center
        DispatchQueue.main.async {
            whiteSpiView.addSubview(indicador)
            naView.addSubview(whiteSpiView)
        }
        return whiteSpiView
    }

    class func removeSpinner(spinner: UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
}












