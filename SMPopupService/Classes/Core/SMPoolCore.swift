//
//  SMPoolCore.swift
//  PopupTest
//
//  Created by 董德富 on 2023/9/5.
//

import Foundation
import UIKit

class SMPoolCore {
    /// paush时isShown可能为true, 所以需要综合判断
    var isShowing: Bool {
        isShown && (currentInterperter != nil)
    }
    /// 是否有弹窗正在展示
    private var isShown: Bool = false
    
    private let safePool: SMSafePool = SMSafePool()
    
    private let subcribe: SMPopupSubcribe = SMPopupSubcribe()

    ///  当前弹窗
    private var currentInterperter: SMPopupInterpreter?
    
    
    /// 放入队列并开始展示
    /// - Parameter inter: 弹窗
    func run(_ inter: SMPopupInterpreter) {
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
