//
//  SMPopupService.swift
//  PopupTest
//
//  Created by 董德富 on 2023/9/1.
//

import Foundation
import UIKit

@objcMembers
public class SMPopupService: NSObject {
    
    /// 弹窗展示方法, 添加进入展示队列
    /// 如果传入view, 也可以内部实现 dataSource和delegate, 但是 customPopupView 会被忽略
    /// 如果不实现dataSource, view需要提前设置frame
    /// - Parameters:
    ///   - config: 弹窗设置参数
    ///   - view: 弹窗view
    public class func show(config: SMPopupConfig, view: UIView) {
        let interpreter = SMPopupInterpreter(config: config, popupView: view)
        SMPoolCoreControl.instance.run(interpreter)
    }
    
    /// 弹窗展示方法, 添加进入展示队列  view和dataSource.customPopupView 有且必须有一个
    /// - Parameters:
    ///   - config: 弹窗设置参数
    ///   - view: 弹窗view
    ///   - dataSource: dataSource 为历史弹窗迁移提供, 比如VC
    ///   - delegate: delegate 为历史弹窗迁移提供, 比如VC
    ///   - event: 事件回调, 可以发送自定义事件并且附带参数. 注意如果是自定义事件, 需要检查跟当前弹窗是否匹配
    public class func show(config: SMPopupConfig,
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
        SMPoolCoreControl.instance.run(interpreter)
    }
    
    /// 弹窗展示, 不加入队列单独展示
    /// - Parameters:
    ///   - config: 弹窗设置参数
    ///   - view: 弹窗view
    ///   - dataSource: dataSource 为历史弹窗迁移提供, 比如VC
    ///   - delegate: delegate 为历史弹窗迁移提供, 比如VC
    ///   - event: 事件回调, 可以发送自定义事件并且附带参数. 注意如果是自定义事件, 需要检查跟当前弹窗是否匹配
    /// - Returns: SMPopupViewProtocol 协议类型, dismiss和sendEvent需要使用protol操作
    public class func showSingle(config: SMPopupConfig,
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
    public class func sendEvent(_ event: SMPopupEvent) {
        SMPoolCoreControl.instance.sendEvent(event: event)
    }
    
    /// 消失当前弹窗, 默认只操作主队列
    public class func dismiss() {
        SMPoolCoreControl.instance.exit()
    }
    
    public class func dismiss(animate: Bool = true,
                              identifier: SMPopupIdentifier? = nil,
                              complete: (() -> Void)? = nil) {
        SMPoolCoreControl.instance.exit(identifier: identifier, complete: complete)
    }
    
    /// 当前是否有弹窗展示
    /// - Returns: 是否在展示
    public class func isShowing() -> Bool {
        SMPoolCoreControl.instance.isShowing()
    }

    /// 暂停所有弹窗展示
    /// 暂停后一定要恢复, 否则后续弹窗都无法展示
    public class func pause() {
        SMPoolCoreControl.instance.pauseShow()
    }
    
    /// 恢复所有弹窗展示
    public class func `continue`() {
        SMPoolCoreControl.instance.continueShow()
    }
    
    /// 挂起当前弹窗 (隐藏掉)
    public class func suspend() {
        SMPoolCoreControl.instance.suspend()
    }
    
    /// 恢复当前弹窗
    public class func recover() {
        SMPoolCoreControl.instance.recover()
    }
    
    /// 删除特定level弹窗数据
    /// - Parameter level: Level
    public class func clear(level: SMPopupLevel) {
        SMPoolCoreControl.instance.clearPopupView(level: level)
    }
    
    /// 删除特定弹窗数据
    /// - Parameter identifier: Id
    public class func clear(identifier: SMPopupIdentifier) {
        SMPoolCoreControl.instance.clearPopupView(identifier: identifier)
    }
    
    /// 清除所有弹窗数据
    public class func forceClearAll() {
        SMPoolCoreControl.instance.forceClear()
    }
    
    /// 判断当前展示弹窗是否为特定id
    /// - Parameter identifier: 弹窗id
    /// - Returns: bool
    public class func isShowing(identifier: SMPopupIdentifier) -> Bool {
        SMPoolCoreControl.instance.isShowing(identifier: identifier)
    }
    
    /// 返回当前展示弹窗数据, 优先返回主队列
    /// - Returns: 弹窗数据
    public class func currentItem() -> SMPopupConfig? {
        return SMPoolCoreControl.instance.currentItem()
    }
    
    /// 更新特定弹窗布局
    /// - Parameters:
    ///   - identifier: 弹窗 id, 如果为空则更新当前弹窗
    ///   - animate: 动画
//    public class func updateLayout(identifier: SMPopupIdentifier? = nil, animate: Bool = true) {
//        SMPoolCoreControl.instance.updateLayout(identifier: identifier, animate: animate)
//    }
}

/// 特定队列操作, 为OC适配
extension SMPopupService {
    
    /// 为特定队列发送自定义事件
    /// 注意只会发送给当前展示弹窗
    /// - Parameters:
    ///   - event: 自定义事件
    ///   - queue: 特定队列
    public class func sendEvent(_ event: SMPopupEvent, queue: SMPopupQueueType) {
        SMPoolCoreControl.instance.sendEvent(event: event, queue)
    }
    
    /// 消失当前弹窗
    public class func dismiss(animate: Bool = true,
                              queue: SMPopupQueueType = .default,
                              identifier: SMPopupIdentifier? = nil,
                              complete: (() -> Void)? = nil) {
        SMPoolCoreControl.instance.exit(identifier: identifier, queue: queue, complete: complete)
    }
    
    /// 当前是否有特定队列弹窗展示
    /// - Parameter queue: 特定队列
    /// - Returns: 是否在展示
    public class func isShowing(queue: SMPopupQueueType) -> Bool {
        SMPoolCoreControl.instance.isShowing(queue)
    }
    
    /// 暂停特定队列弹窗展示
    /// - Parameter queue: 特定队列
    public class func pause(queue: SMPopupQueueType) {
        SMPoolCoreControl.instance.pauseShow(queue)
    }
    
    /// 暂停特定队列弹窗展示
    /// - Parameter queue: 特定队列
    public class func `continue`(queue: SMPopupQueueType) {
        SMPoolCoreControl.instance.continueShow(queue)
    }
    
    /// 挂起特定队列当前弹窗 (隐藏掉)
    /// - Parameter queue: 特定队列
    public class func suspend(queue: SMPopupQueueType) {
        SMPoolCoreControl.instance.suspend(queue)
    }
    
    /// 恢复特定队列当前弹窗
    /// - Parameter queue: 特定队列
    public class func recover(queue: SMPopupQueueType) {
        SMPoolCoreControl.instance.recover(queue)
    }
    
    /// 删除特定level弹窗数据
    /// - Parameters:
    ///   - level: 特定层级
    ///   - queue: 特定队列
    public class func clear(level: SMPopupLevel, queue: SMPopupQueueType) {
        SMPoolCoreControl.instance.clearPopupView(level: level, queue)
    }
    
    /// 删除特定弹窗数据
    /// - Parameters:
    ///   - identifier: 弹窗id
    ///   - queue: 特定队列
    public class func clear(identifier: SMPopupIdentifier, queue: SMPopupQueueType) {
        SMPoolCoreControl.instance.clearPopupView(identifier: identifier, queue)
    }
    
    /// 清除特定队列所有弹窗数据
    /// - Parameter queue: 特定队列
    public class func forceClearAll(queue: SMPopupQueueType) {
        SMPoolCoreControl.instance.forceClear(queue)
    }
    
    /// 判断特定队列当前展示弹窗是否为特定id
    /// - Parameters:
    ///   - identifier: 弹窗id
    ///   - queue: 特定队列
    /// - Returns: bool
    public class func isShowing(identifier: SMPopupIdentifier, queue: SMPopupQueueType) -> Bool {
        SMPoolCoreControl.instance.isShowing(identifier: identifier, queue)
    }
    
    /// 返回特定队列当前展示弹窗数据
    /// - Parameter queue: 特定队列
    /// - Returns: 弹窗数据
    public class func currentItem(queue: SMPopupQueueType) -> SMPopupConfig? {
        return SMPoolCoreControl.instance.currentItem(queue)
    }
    
    /// 更新特定队列 特定弹窗布局
    /// - Parameters:
    ///   - identifier: 弹窗 id, 如果为空则更新当前弹窗
    ///   - animate: 动画
    ///   - queue: 特定队列
//    public class func updateLayout(identifier: SMPopupIdentifier? = nil, animate: Bool = true, queue: SMPopupQueueType) {
//        SMPoolCoreControl.instance.updateLayout(identifier: identifier, animate: animate, queue)
//    }
}
