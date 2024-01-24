//
//  CenterVC.swift
//  PopupTest
//
//  Created by 董德富 on 2023/9/7.
//

import Foundation
import UIKit
import SMPopupService

class CenterVC: UIViewController, SMPopupViewDataSource, SMPopupViewDelegate {
    override func viewDidLoad() {
        let center = CenterPopView()
        center.callbackBlock = { _ in
            SMPopupService.dismiss()
        }
        view.addSubview(center)
        
        center.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func layout(superView: UIView) {
        view.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    func customPopupView() -> UIView {
        view
    }
}

