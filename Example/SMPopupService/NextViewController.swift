//
//  NextViewController.swift
//  PopupTest
//
//  Created by 董德富 on 2024/1/9.
//

import Foundation
import UIKit
import SMPopupService

class NextViewController: UIViewController {
    override func loadView() {
        super.loadView()
        
        view = CustomView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            self.navigationController?.popViewController(animated: true)
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        let config = SMPopupConfig(sceneStyle: .center)
        config.cornerRadius = 0
        config.containerView = view
//        config.showAnimationStyle = .bottomRise
//        config.dismissAnimationStyle = .bottomFall
        config.identifier = "center"
        let pop = CenterPopView()
        pop.callbackBlock = { _ in
            SMPopupService.standard.dismiss {
                print("complete")
            }
        }
        SMPopupService.standard.show(config: config, view: pop)
    }
    
    deinit {
        print("\(type(of: self)) -> \(#function)")
    }
    
    class CustomView: UIView {
        deinit {
            print("\(type(of: self)) -> \(#function)")
        }
    }
}
