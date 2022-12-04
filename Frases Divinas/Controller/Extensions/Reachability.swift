//
//  Reachability.swift
//  Frases Divinas
//
//  Created by Filipe Merli on 13/04/2018.
//  Copyright © 2018 Filipe Merli. All rights reserved.
//

import Foundation
import SystemConfiguration

public class Reachability {
    class func temConexaoDeInternet() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        let defaultRouterReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }

        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouterReachability!, &flags) == false {
            return false
        }

        let ehReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let precisaDeConexao = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let retorno = (ehReachable && !precisaDeConexao)

        return retorno
    }
}



