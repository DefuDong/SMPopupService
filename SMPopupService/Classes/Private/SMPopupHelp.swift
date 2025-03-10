//
//  SMPopupHelp.swift
//  PopupTest
//
//  Created by 董德富 on 2024/1/23.
//

import Foundation
import UIKit

extension UIApplication {
    public func getKeyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            for scene in scenes {
                if let scene = scene as? UIWindowScene, scene.activationState == .foregroundActive {
                    for window in scene.windows {
                        if window.isKeyWindow { return window }
                    }
                }
            }
            
            if #unavailable(iOS 15.0) {
                let windows = UIApplication.shared.windows
                for window in windows {
                    if window.isKeyWindow { return window }
                }
            }
            return nil
        } else {
            return keyWindow
        }
    }
}

extension UIScreen {
    public static func p_safeArea() -> UIEdgeInsets? {
        return UIApplication.shared.getKeyWindow()?.safeAreaInsets
    }
    
    public static func p_safeTop() -> CGFloat {
        if let top = UIScreen.p_safeArea()?.top {
            return top
        }
        var top: CGFloat = 20
        if #unavailable(iOS 13.0) {
            top = UIApplication.shared.statusBarFrame.size.height
        }
        return top
    }
}

private var popupProtolKey: UInt8 = 0
extension UIView {
    /// 获取当前单独管理弹窗的protocol操作对象
    /// 只有使用showSingle单独 弹出/管理 的弹窗才可以使用, 队列管理弹窗不要使用!!!
    @objc public var popupViewProtocol: SMPopupViewProtocol? {
        get {
            //获取warpper, 并从中获取到值
            if let warpper = objc_getAssociatedObject(self, &popupProtolKey) as? WeakObjWrapper {
                return warpper.weakObj as? SMPopupViewProtocol
            }
            return nil
        }
        set {
            var warpper = objc_getAssociatedObject(self, &popupProtolKey) as? WeakObjWrapper
            if let warpper = warpper {
                //已存在直接赋值
                warpper.weakObj = newValue
            } else {
                //warpper不存在则创建
                warpper = WeakObjWrapper(weakObj: newValue)
            }
            //保存warpper对象
            objc_setAssociatedObject(self, &popupProtolKey, warpper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 中间对象, 防止强引用
    private class WeakObjWrapper: Any {
        weak var weakObj: AnyObject?
        init(weakObj: AnyObject?) {
            self.weakObj = weakObj
        }
    }
}


