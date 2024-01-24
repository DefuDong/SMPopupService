//
//  SMPopupMaskView.swift
//  PopupTest
//
//  Created by 董德富 on 2023/9/5.
//

import Foundation
import UIKit

class SMPopupMaskView: UIView, UIGestureRecognizerDelegate {
    
    var hideMask: Bool = false
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView == self && hideMask {
            return nil
        }
        return hitView
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let touchView = touch.view else { return false }
        if touchView == self && !hideMask {
            return true
        }
        return false
    }
}
