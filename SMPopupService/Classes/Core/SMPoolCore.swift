//
//  SMPoolCore.swift
//  PopupTest
//
//  Created by 董德富 on 2023/9/5.
//

import Foundation
import UIKit

/**
 * 弹窗池核心管理类
 * 
 * 功能说明：
 * - 管理弹窗队列的添加、移除和显示
 * - 控制弹窗的优先级排序和显示顺序
 * - 处理弹窗的暂停、恢复和清除操作
 * - 管理当前显示的弹窗状态
 * 
 * 核心机制：
 * - 使用SMSafePool管理弹窗队列，支持优先级排序
 * - 使用SMPopupSubcribe处理弹窗事件和状态变化
 * - 确保同一时间只有一个弹窗显示
 * - 支持弹窗的自动切换和手动控制
 * 
 * 状态管理：
 * - isShowing: 综合判断是否有弹窗正在显示
 * - isShown: 内部状态标记
 * - currentInterperter: 当前显示的弹窗解释器
 * 
 * 线程安全：
 * - 内部使用SMSafePool的线程安全机制
 * - 所有操作都在独立队列中执行
 * - UI操作自动切换到主线程
 */
class SMPoolCore {
    /// 是否有弹窗正在显示
    /// - Note: 综合判断isShown和currentInterperter，确保状态准确性
    /// - Returns: true表示有弹窗正在显示，false表示没有
    var isShowing: Bool {
        isShown && (currentInterperter != nil)
    }
    
    /// 内部显示状态标记
    /// - Note: 用于跟踪弹窗的显示状态，pause时可能为true
    private var isShown: Bool = false
    
    /// 安全弹窗池
    /// - Note: 使用优先级队列管理弹窗，支持线程安全操作
    private let safePool: SMSafePool = SMSafePool()
    
    /// 弹窗订阅管理器
    /// - Note: 处理弹窗事件订阅和状态变化通知
    private let subcribe: SMPopupSubcribe = SMPopupSubcribe()

    /// 当前显示的弹窗解释器
    /// - Note: 记录当前正在显示的弹窗，用于状态管理和控制
    private var currentInterperter: SMPopupInterpreter?
    
    
    /// 将弹窗放入队列并开始展示
    /// - Parameter inter: 弹窗解释器对象
    /// - Note: 此方法会检查无用弹窗，将新弹窗加入队列，并尝试显示
    func run(_ inter: SMPopupInterpreter) {
        // 检查并清理无用的弹窗
        checkUselessPopup()
        
        inter.dismissCalledBlock = { [weak self] in
            self?.dismissPopupView()
        }
        
        inter.abnormalDismissBlock = { [weak self] in
            self?.dismissPopupView(force: true)
        }
        
        //如果加入配置为showImmediately
        if inter.config.level == .maxAndImmediately {
            if let _ = currentInterperter { //有正在展示
                //dismiss当前
                dismissPopupView(force: true, canContinue: false)
            } else if isShown { //当前是pause状态, 直接放入队列
                safePool.push(inter)
                return
            }
            currentInterperter = inter
            
            isShown = inter.show()
        } else { //正常加入
            //放入队列
            safePool.push(inter)
            
            //展示
            if !isShown {
                showPopupView()
            }
        }
    }
    
    /// 消除当前弹窗
    /// - Parameters:
    ///   - animate: 动画
    ///   - identifier: identifier
    ///   - complete: complete description
    func exit(animate: Bool = true,
              identifier: SMPopupIdentifier? = nil,
              complete: (() -> Void)? = nil) {
        if let identifier = identifier {
            //identifier 不匹配, 直接返回
            if let curId = currentInterperter?.config.identifier, curId == identifier {
                dismissPopupView(force: !animate, complete: complete)
            }
        } else {
            dismissPopupView(force: !animate, complete: complete)
        }
    }
    
    /// 挂起当前倒计时弹窗
    func suspend() {
        guard let cur = currentInterperter, let pop = cur.popupView,
                pop.isHidden == false else { return }
        
        pop.isHidden = true
        cur.stopTimer()
    }
    
    func recover() {
        guard let pop = currentInterperter?.popupView, isShown && pop.isHidden else { return }
        pop.isHidden = false
        currentInterperter?.startTimer()
    }
    
    func pauseShow() {
        //清除当前展示
        if isShown {
            dismissPopupView(force: true, canContinue: false)
        }
        isShown = true
    }
    
    func continueShow() {
        isShown = false
        if currentInterperter == nil && !safePool.isEmpty() {
            showPopupView()
        }
    }
    
    func clearPopupView(level: SMPopupLevel) {
        safePool.clear(level: level)
        //查看当前是否有相关弹窗弹出，有则判断
        if let curLevel = currentInterperter?.config.level,
            isShown && curLevel == level {
            DispatchQueue.main.async {
                self.dismissPopupView()
            }
        } else if isEmpty() {
            subcribe.notifyListeners(.empty)
        }
    }
    
    func clearPopupView(identifier: SMPopupIdentifier) {
        safePool.clear(identifier: identifier)
        //查看当前是否有相关弹窗弹出，有则判断
        if let curId = currentInterperter?.config.identifier,
            isShown && curId == identifier {
            DispatchQueue.main.async {
                self.dismissPopupView()
            }
        } else if isEmpty() {
            subcribe.notifyListeners(.empty)
        }
    }
    
    func isShowing(identifier: SMPopupIdentifier) -> Bool {
        guard let curId = currentInterperter?.config.identifier, isShown else { return false }
        return curId == identifier
    }
    
    func isEmpty() -> Bool {
        return safePool.isEmpty()
    }
    
    func currentItem() -> SMPopupConfig? {
        guard let config = currentInterperter?.config, isShown else { return nil }
        return config
    }
    
    func currentPopupView(identifier: SMPopupIdentifier?) -> UIView? {
        guard let view = currentInterperter?.popupView, isShown else { return nil }
        if let identifier = identifier {
            if identifier == currentInterperter?.config.identifier {
                return view
            } else {
                return nil
            }
        } else {
            return view
        }
    }

    func forceClear() {
        safePool.clearAll()
        
        //清除当前展示
        if isShown {
            dismissPopupView(force: true, canContinue: false)
        } else {
            subcribe.notifyListeners(.empty)
        }
    }
    
    func sendEvent(_ event: SMPopupEvent) {
        if let currentInterperter = currentInterperter {
            currentInterperter.sendEvent(event)
        }
    }
    
    func updateLayout(identifier: SMPopupIdentifier? = nil, animate: Bool = true) {
        if let identifier = identifier {
            if let curPop = currentInterperter, let curId = curPop.config.identifier, curId == identifier {
                curPop.updateLayout(animate: animate)
            }
        } else {
            currentInterperter?.updateLayout(animate: animate)
        }
    }
    
    func addListener(_ listener: AnyObject, callback: @escaping SMPopupSubcribeCallback) {
        subcribe.addListener(listener, callback: callback)
    }
}

/// show  & dismiss
extension SMPoolCore {
    private func showPopupView() {
        guard let top = safePool.top() as? SMPopupInterpreter else { return }
        
        let checkResult = top.config.checkShowResult()
        switch checkResult {
        case .show: //正常展示
            currentInterperter = top
            safePool.pop()
            isShown = top.show()
        case .discardedContinue: //丢弃当前, 继续展示下一个
            safePool.pop()
            showPopupView()
        case .discardedPause: //丢弃当前, 暂停
            safePool.pop()
        default: //pause什么都不做
            break
        }
    }
    
    /// dismiss
    /// - Parameters:
    ///   - force: 不展示动画, 直接移除
    ///   - canContinue: 是否继续展示下一个
    private func dismissPopupView(force: Bool = false,
                                  canContinue: Bool = true,
                                  complete: (() -> Void)? = nil) {
        guard let cur = currentInterperter else { return }
        
        cur.dismiss(force) { [weak self] in
            guard let self = self else { return }
            
            if self.isShown {
                self.currentInterperter = nil
                self.isShown = false
            }
            
            complete?()
            
            if !self.safePool.isEmpty() {
                //如果pool不为空, 展示下一个
                if canContinue {
                    self.showPopupView()
                }
            } else {
                subcribe.notifyListeners(.empty)
            }            
        }
    }
    
    private func checkUselessPopup() {
        guard let currentInterperter = currentInterperter else { return }
        
        //如果当前Interperter 的 popupView 不存在, Interperter 置为 nil
        if currentInterperter.popupView == nil {
            self.currentInterperter = nil
            isShown = false
        }
    }
}
