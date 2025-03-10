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

    convenience init(abnormalDismissBlock: (() -> Void)?) {
        self.init(frame: .zero)
        backgroundColor = .clear
        self.abnormalDismissBlock = abnormalDismissBlock
    }
    
    /// 弹窗异常消失回调, 不在当前视图层及展示,比如控制器右滑, 没有调用正常消失代码
    private var abnormalDismissBlock: (() -> Void)?

    private var isRemoveByCalledFunction: Bool = false

    override func removeFromSuperview() {
        isRemoveByCalledFunction = true
        super.removeFromSuperview()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        // 从父视图异常移除
        if window == nil && isSpuerVCDismissed() &&
            isRemoveByCalledFunction == false {
            abnormalDismissBlock?()
        }
    }
    
    /// 判断当前视图的父VC是否已经从视图栈移除 .
    ///  如果present一个vc, 会导致 will/did MoveToWindow 被调用,当前window会被置为nil
    ///  导航push到下一个vc, 也会导致 window被调用. 当前vc会先从widow移除, 再被添加
    /// - Returns: 当前视图的vc是否已被移除
    private func isSpuerVCDismissed() -> Bool {
        func isOnStack(view: UIView?) -> Bool {
            guard let view = view else { return false }
            return String(describing: type(of: view.self)) == "UILayoutContainerView" || view is UIWindow
        }
        
        var nextSuper = superview
        while nextSuper != nil {
            if isOnStack(view: nextSuper) {
                return false
            }
            //如果是在导航栈中, 需要遍历navigationController.view
            if let navigationController = (nextSuper?.next as? UIViewController)?.navigationController {
                var navNext = navigationController.view
                while navNext != nil {
                    if isOnStack(view: navNext) {
                        return false
                    }
                    navNext = navNext?.superview
                }
            }
            nextSuper = nextSuper?.superview
        }
        return true
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
