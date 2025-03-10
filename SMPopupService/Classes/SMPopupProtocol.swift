//
//  SMPopupProtocol.swift
//  PopupTest
//
//  Created by 董德富 on 2023/8/31.
//

import Foundation
import UIKit

@objc
public protocol SMPopupViewDataSource: NSObjectProtocol {
    
    /// 提供一个自定义的弹窗对象
    /// - Returns: 弹窗view
    @objc optional func customPopupView() -> UIView
    
    
    /// 执行自定义布局
    /// - Parameter superView: superView
    @objc optional func layout(superView: UIView)
    
    
    /// 执行自定义展示动画
    /// 如果实现, 则会忽略 showAnimationStyle
    /// - Parameter complete: 动画完成通知, 必须调用 complete description
    @objc optional func executeCustomShowAnimation(complete: @escaping (Bool) -> Void)
    
    /// 执行自定义消失动画
    /// 如果实现, 则会忽略 dismissAnimationStyle
    /// - Parameter complete: 动画完成通知, 必须调用 complete description
    @objc optional func executeCustomDismissAnimation(complete: @escaping (Bool) -> Void)
}

@objc
public protocol SMPopupViewDelegate: NSObjectProtocol {
    @objc optional func popupWillAppear()
    @objc optional func popupDidAppear()
    @objc optional func popupWillDisappear()
    @objc optional func popupDidDisappear()
}

@objc
public protocol SMPopupViewProtocol: NSObjectProtocol {
    @objc func dismissSingle(_ animate: Bool, completion: (() -> Void)?)
    
    @objc func sendEventSingle(_ event: SMPopupEvent)
    
    @objc func updateLayoutSingle(animate: Bool)
}
