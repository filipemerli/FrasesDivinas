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
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let activIndic = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        activIndic.startAnimating()
        activIndic.center = spinnerView.center
        DispatchQueue.main.async {
            spinnerView.addSubview(activIndic)
            onView.addSubview(spinnerView)
        }
        return spinnerView
    }
    
    class func removeSpinner(spinner :UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
        }
    }
}












