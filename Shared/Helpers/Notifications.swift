//
//  Notifications.swift
//  Recon Bolt (iOS)
//
//  Created by Sjors Schijff on 16/02/2023.
//

import Foundation

extension NSNotification.Name {

    static let userAccountChanged = Notification.Name("userAccountChanged")

}

extension Notification {

    static let userAccountChanged = Notification(name: .userAccountChanged)

}
