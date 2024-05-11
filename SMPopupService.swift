//
//  SMPopupService.swift
//  SMPopupService
//
//  Created by 董德富 on 2024/5/10.
//

import Foundation
import UIKit

@objcMembers
public class SMPopupService: NSObject {
    
    /// 默认展示队列
    public static let standard = SMPopupService()
    
    /// 共存展示队列
    public static let coexistence = SMPopupService()
    private let core: SMPoolCore
    
    /// 需要更多队列请自行创建新的实例
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
    public func showSingle(config: SMPopupConfig,
                                 view: UIView? = nil,
                                 dataSource: SMPopupViewDataSource? = nil,
                                 delegate: SMPopupViewDelegate? = nil,
                                 event: SMPopupEventBlock? = nil) -> SMPopupViewProtocol {
        assert((view == nil && dataSource != nil) || (view != nil && dataSource == nil) , "view or customPopupView only need one")
        assert(view != nil || dataSource?.customPopupView?() != nil, "view or customPopupView need be implemented")
        let interpreter = SMPopupInterpreter(config: config,
                                             popupView: view,
                                             dataSource: dataSource,
                                             delegate: delegate)
        interpreter.eventBlock = event
        interpreter.dismissCalledBlock = { [weak interpreter] in
            interpreter?.dismiss()
        }
        let _ = interpreter.show()
        return interpreter
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
    /// 暂停后一定要恢复, 否则后续弹窗都无法展示
    public func pause() {
        core.pauseShow()
    }
    
    /// 恢复所有弹窗展示
    public func `continue`() {
        core.continueShow()
    }
    
    /// 挂起当前弹窗 (隐藏掉)
    public func suspend() {
        core.suspend()
    }
    
    /// 恢复当前弹窗
    public func recover() {
        core.recover()
    }
    
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
    
    /// 返回当前展示弹窗数据, 优先返回主队列
    /// - Returns: 弹窗数据
    public func currentItem() -> SMPopupConfig? {
        return core.currentItem()
    }
    
    
    
    private func runMain(_ work: @escaping @convention(block) () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async { work() }
        }
    }
}
