//
//  SMPopupService.swift
//  SMPopupService
//
//  Created by 董德富 on 2024/5/10.
//

import Foundation
import UIKit

/**
 * 弹窗服务主类
 * 
 * 功能说明：
 * - 提供弹窗的创建、显示、隐藏和管理功能
 * - 支持队列管理和单独弹窗两种模式
 * - 提供多种弹窗样式和动画效果
 * - 支持优先级队列，确保重要弹窗优先显示
 * 
 * 架构设计：
 * - 使用单例模式提供标准队列和共存队列
 * - 通过SMPoolCore管理弹窗队列
 * - 支持自定义队列实例，满足不同业务需求
 * - 新架构支持弹窗view自动管理生命周期
 * 
 * 使用方式：
 * - 队列模式：SMPopupService.standard.show() - 按优先级排队显示
 * - 单独模式：SMPopupService.showSingle() - 直接显示，自动管理生命周期
 * - 自定义队列：创建SMPopupService实例 - 独立管理弹窗队列
 * 
 * 线程安全：
 * - 所有公共方法都是线程安全的
 * - 内部使用并发队列管理弹窗操作
 * - UI操作自动切换到主线程执行
 */
@objcMembers
public class SMPopupService: NSObject {
    
    /// 默认展示队列
    /// - Note: 单例模式，用于管理大部分弹窗的显示队列
    public static let standard = SMPopupService()
    
    /// 共存展示队列
    /// - Note: 单例模式，用于需要同时显示多个弹窗的场景
    public static let coexistence = SMPopupService()
    
    /// 弹窗核心管理器
    /// - Note: 负责弹窗队列的管理、优先级排序和生命周期控制
    /// - 使用SMSafePool管理弹窗队列，支持线程安全操作
    /// - 自动按优先级排序，确保重要弹窗优先显示
    /// - 同一时间只显示一个弹窗，支持自动切换
    private let core: SMPoolCore
    
    /// 初始化弹窗服务
    /// - Note: 创建新的SMPoolCore实例，用于独立管理弹窗队列
    public override init() {
        core = SMPoolCore()
        super.init()
    }
    
    /// 弹窗展示方法, 添加进入展示队列
    /// 如果传入view, 也可以内部实现 dataSource和delegate, 但是 customPopupView 会被忽略
    /// 如果不实现dataSource, view需要提前设置frame
    /// - Parameters:
    ///   - config: 弹窗设置参数
    ///   - view: 弹窗view
    public func show(config: SMPopupConfig, view: UIView) {
        let interpreter = SMPopupInterpreter(config: config, popupView: view)
        core.run(interpreter)
    }
    
    /// 弹窗展示方法, 添加进入展示队列  view和dataSource.customPopupView 有且必须有一个
    /// - Parameters:
    ///   - config: 弹窗设置参数
    ///   - view: 弹窗view
    ///   - dataSource: dataSource 为历史弹窗迁移提供, 比如VC
    ///   - delegate: delegate 为历史弹窗迁移提供, 比如VC
    ///   - event: 事件回调, 可以发送自定义事件并且附带参数. 注意如果是自定义事件, 需要检查跟当前弹窗是否匹配
    public func show(config: SMPopupConfig,
                           view: UIView? = nil,
                           dataSource: SMPopupViewDataSource? = nil,
                           delegate: SMPopupViewDelegate? = nil,
                           event: SMPopupEventBlock? = nil) {
        assert((view == nil && dataSource != nil) || (view != nil && dataSource == nil) , "view or customPopupView only need one")
        assert(view != nil || dataSource?.customPopupView?() != nil, "view or customPopupView need be implemented")
        let interpreter = SMPopupInterpreter(config: config,
                                             popupView: view,
                                             dataSource: dataSource,
                                             delegate: delegate)
        interpreter.eventBlock = event
        core.run(interpreter)
    }
    
    /// 弹窗展示, 不加入队列单独展示
    /// - Parameters:
    ///   - config: 弹窗设置参数
    ///   - view: 弹窗view
    ///   - dataSource: dataSource 为历史弹窗迁移提供, 比如VC
    ///   - delegate: delegate 为历史弹窗迁移提供, 比如VC
    ///   - event: 事件回调, 可以发送自定义事件并且附带参数. 注意如果是自定义事件, 需要检查跟当前弹窗是否匹配
    /// - Returns: SMPopupViewProtocol 协议类型, dismiss和sendEvent需要使用protol操作
    /// - Note: 弹窗view会持有配置对象，通过view的dealloc自动管理生命周期
    public class func showSingle(config: SMPopupConfig,
                                 view: UIView? = nil,
                                 dataSource: SMPopupViewDataSource? = nil,
                                 delegate: SMPopupViewDelegate? = nil,
                                 event: SMPopupEventBlock? = nil) -> SMPopupViewProtocol {
        assert((view == nil && dataSource != nil) || (view != nil && dataSource == nil) , "view or customPopupView only need one")
        assert(view != nil || dataSource?.customPopupView?() != nil, "view or customPopupView need be implemented")
        
        // 获取实际的弹窗视图
        let actualView = view ?? dataSource?.customPopupView?()
        guard let popupView = actualView else {
            fatalError("view or customPopupView must be provided")
        }
        
        // 创建弹窗容器
        let container = SMPopupContainer(
            config: config,
            popupView: popupView,
            dataSource: dataSource,
            delegate: delegate,
            event: event
        )
        
        // 将容器关联到弹窗视图
        popupView.popupContainer = container
        popupView.popupViewProtocol = container
        
        // 显示弹窗
        let _ = container.show()
        
        return container
    }
    
    
    /// 发送自定义事件, 默认只发送给主队列
    /// 注意只会发送给当前展示弹窗
    /// - Parameter event: 自定义事件
    public func sendEvent(_ event: SMPopupEvent) {
        core.sendEvent(event)
    }
    
    /// 消失当前弹窗, 默认只操作主队列
    public func dismiss() {
        core.exit()
    }
    
    public func dismiss(animate: Bool = true,
                              identifier: SMPopupIdentifier? = nil,
                              complete: (() -> Void)? = nil) {
        core.exit(identifier: identifier, complete: complete)
    }
    
    /// 当前是否有弹窗展示
    /// - Returns: 是否在展示
    public func isShowing() -> Bool {
        core.isShowing
    }

    /// 暂停所有弹窗展示
    /// 暂停后一定要恢复, 否则后续弹窗都无法展示⚠️
    public func pause() {
        core.pauseShow()
    }
    
    /// 恢复所有弹窗展示
    public func `continue`() {
        core.continueShow()
    }
    
    /// 挂起当前弹窗 (隐藏掉)
//    public func suspend() {
//        core.suspend()
//    }
    
    /// 恢复当前弹窗
//    public func recover() {
//        core.recover()
//    }
    
    /// 删除特定level弹窗数据
    /// - Parameter level: Level
    public func clear(level: SMPopupLevel) {
        core.clearPopupView(level: level)
    }
    
    /// 删除特定弹窗数据
    /// - Parameter identifier: Id
    public func clear(identifier: SMPopupIdentifier) {
        core.clearPopupView(identifier: identifier)
    }
    
    /// 清除所有弹窗数据
    public func forceClearAll() {
        core.forceClear()
    }
    
    /// 判断当前展示弹窗是否为特定id
    /// - Parameter identifier: 弹窗id
    /// - Returns: bool
    public func isShowing(identifier: SMPopupIdentifier) -> Bool {
        core.isShowing(identifier: identifier)
    }
    
    public func isEmpty() -> Bool {
        core.isEmpty()
    }
    
    /// 返回当前展示弹窗数据, 优先返回主队列
    /// - Returns: 弹窗数据
    public func currentItem() -> SMPopupConfig? {
        return core.currentItem()
    }
    
    public func currentPopupView(identifier: SMPopupIdentifier?) -> UIView? {
        return core.currentPopupView(identifier: identifier)
    }
    
    /// 更新特定弹窗布局
    /// - Parameters:
    ///   - identifier: 弹窗 id, 如果为空则更新当前弹窗
    ///   - animate: 动画
    public func updateLayout(identifier: SMPopupIdentifier? = nil, animate: Bool = true) {
        core.updateLayout(identifier: identifier, animate: animate)
    }
    
    public func addListener(_ listener: AnyObject, callback: @escaping SMPopupSubcribeCallback) {
        core.addListener(listener, callback: callback)
    }
    
    private func runMain(_ work: @escaping @convention(block) () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async { work() }
        }
    }
}
