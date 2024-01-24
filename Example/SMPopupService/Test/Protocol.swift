//
//  Protocol.swift
//  PopupTest
//
//  Created by 董德富 on 2023/9/6.
//

import Foundation
import UIKit
import SMPopupService

protocol SMProtocol: SMPopupViewDataSource, SMPopupViewDelegate {
    var label: UILabel { get }
}
