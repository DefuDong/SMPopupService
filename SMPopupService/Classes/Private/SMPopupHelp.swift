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
