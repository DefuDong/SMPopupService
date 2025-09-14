//
//  SMPopupHelp.swift
//  PopupTest
//
//  Created by 董德富 on 2024/1/23.
//

import Foundation
import UIKit

/**
 * 弹窗容器类
 * 
 * 功能说明：
 * - 管理单独弹窗的生命周期
 * - 持有SMPopupInterpreter和SMPopupConfig
 * - 通过弹窗view的dealloc自动释放
 * - 提供弹窗控制接口
 */
public class SMPopupContainer: NSObject {
    
    /// 弹窗解释器
    private let interpreter: SMPopupInterpreter
    
    /// 弹窗配置
    private let config: SMPopupConfig
    
    /// 弹窗视图
    private weak var popupView: UIView?
    
    /// 是否已经显示
    private var isShown: Bool = false
    
    /// 初始化方法
    /// - Parameters:
    ///   - config: 弹窗配置
    ///   - popupView: 弹窗视图
    ///   - dataSource: 数据源
    ///   - delegate: 代理
    ///   - event: 事件回调
    public init(config: SMPopupConfig,
                popupView: UIView? = nil,
                dataSource: SMPopupViewDataSource? = nil,
                delegate: SMPopupViewDelegate? = nil,
                event: SMPopupEventBlock? = nil) {
        
        self.config = config
        self.popupView = popupView
        
        // 创建解释器
        self.interpreter = SMPopupInterpreter(
            config: config,
            popupView: popupView,
            dataSource: dataSource,
            delegate: delegate
        )
        
        super.init()
        
        // 设置事件回调
        interpreter.eventBlock = event
        
        // 设置dismiss回调
        interpreter.dismissCalledBlock = { [weak self] in
            self?.dismiss()
        }
    }
    
    /// 显示弹窗
    /// - Returns: 是否显示成功
    @discardableResult
    public func show() -> Bool {
        guard !isShown else { return false }
        
        isShown = interpreter.show(true)
        return isShown
    }
    
    /// 关闭弹窗
    /// - Parameters:
    ///   - animate: 是否使用动画
    ///   - completion: 完成回调
    public func dismiss(animate: Bool = true, completion: (() -> Void)? = nil) {
        guard isShown else {
            completion?()
            return
        }
        
        interpreter.dismiss(!animate) { [weak self] in
            self?.isShown = false
            completion?()
        }
    }
    
    /// 发送事件
    /// - Parameter event: 事件对象
    public func sendEvent(_ event: SMPopupEvent) {
        interpreter.sendEvent(event)
    }
    
    /// 更新布局
    /// - Parameter animate: 是否使用动画
    public func updateLayout(animate: Bool = true) {
        interpreter.updateLayout(animate: animate)
    }
    
    /// 获取弹窗视图
    /// - Returns: 弹窗视图
    public func getPopupView() -> UIView? {
        return popupView
    }
    
    /// 获取弹窗配置
    /// - Returns: 弹窗配置
    public func getConfig() -> SMPopupConfig {
        return config
    }
}

// MARK: - SMPopupViewProtocol
extension SMPopupContainer: SMPopupViewProtocol {
    
    public func dismissSingle(_ animate: Bool, completion: (() -> Void)?) {
        dismiss(animate: animate, completion: completion)
    }
    
    public func sendEventSingle(_ event: SMPopupEvent) {
        sendEvent(event)
    }
    
    public func updateLayoutSingle(animate: Bool) {
        updateLayout(animate: animate)
    }
}

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
private var popupContainerKey: UInt8 = 1

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
    
    /// 获取弹窗容器对象
    /// 用于管理弹窗的生命周期
    @objc public var popupContainer: SMPopupContainer? {
        get {
            return objc_getAssociatedObject(self, &popupContainerKey) as? SMPopupContainer
        }
        set {
            objc_setAssociatedObject(self, &popupContainerKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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


