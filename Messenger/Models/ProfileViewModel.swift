//
//  ProfileViewModel.swift
//  Messenger
//
//  Created by Kadir Yildiz on 13/10/2024.
//

import Foundation

enum ProfileViewModelType {
    case info, logOut
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
