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
 * - 管理单独弹窗的生命周期，不通过队列管理
 * - 持有SMPopupInterpreter和SMPopupConfig，提供完整的弹窗控制
 * - 通过弹窗view的dealloc自动释放，避免内存泄漏
 * - 提供弹窗控制接口，支持显示、隐藏、事件发送等操作
 * 
 * 架构设计：
 * - 作为单独弹窗的包装器，实现SMPopupViewProtocol协议
 * - 通过关联对象与UIView绑定，实现自动生命周期管理
 * - 支持弹窗叠加显示，不受队列优先级限制
 * 
 * 使用场景：
 * - 需要独立管理的弹窗（如引导页、提示框等）
 * - 需要叠加显示的弹窗（如多个提示同时显示）
 * - 需要精确控制生命周期的弹窗
 * 
 * 生命周期：
 * - 创建时：初始化解释器和配置
 * - 显示时：调用解释器的show方法
 * - 隐藏时：调用解释器的dismiss方法
 * - 释放时：通过view的dealloc自动清理
 */
public class SMPopupContainer: NSObject {
    
    /// 弹窗解释器
    /// - Note: 负责弹窗的实际显示、隐藏和动画控制
    /// - 封装了所有弹窗操作的具体实现
    private let interpreter: SMPopupInterpreter
    
    /// 弹窗配置
    /// - Note: 包含弹窗的样式、动画、优先级等配置信息
    /// - 在容器创建时确定，后续不可修改
    private let config: SMPopupConfig
    
    /// 弹窗视图
    /// - Note: 实际的弹窗UI视图，使用弱引用避免循环引用
    /// - 当view被释放时，容器也会自动释放
    private weak var popupView: UIView?
    
    /// 是否已经显示
    /// - Note: 跟踪弹窗的显示状态，防止重复显示
    /// - 用于状态管理和控制
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


