//
//  SMPoolCore.swift
//  PopupTest
//
//  Created by 董德富 on 2023/9/5.
//

import Foundation
import UIKit

class SMPoolCore {
    
    init(queue: DispatchQueue? = nil) {
        self.queue = queue ?? DispatchQueue(label: "Popup.Queue", attributes: .concurrent)
        self.safePool = SMSafePool(queue: queue)
    }

    /// paush时isShown可能为true, 所以需要综合判断
    var isShowing: Bool {
        isShown && (currentInterperter != nil)
    }
    /// 是否有弹窗正在展示
    private var isShown: Bool = false

    /// 展示队列
    private let queue: DispatchQueue
    
    private let safePool: SMSafePool
        
    ///  当前弹窗
    private var currentInterperter: SMPopupInterpreter?
    
    
    /// 放入队列并开始展示
    /// - Parameter inter: 弹窗
    func run(_ inter: SMPopupInterpreter) {
        checkUselessPopup()
        
        inter.dismissCalledBlock = { [weak self] in
            self?.dismissPopupView()
        }
        
        //如果加入配置为showImmediately
        if inter.config.level == .maxAndImmediately {
            if let cur = currentInterperter { //真实有在展示
                if cur.config.level == .maxAndImmediately { //当前也是immediately, 直接放入队列
                    safePool.push(inter)
                    return
                } else { //dismiss当前, 放回队列
                    dismissPopupView(force: true, canContinue: false)
                    safePool.push(cur)
                }
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
        if !safePool.isEmpty() {
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
        }
    }
    
    func isShowing(identifier: SMPopupIdentifier) -> Bool {
        guard let curId = currentInterperter?.config.identifier, isShown else { return false }
        return curId == identifier
    }
    
    func currentItem() -> SMPopupConfig? {
        guard let config = currentInterperter?.config, isShown else { return nil }
        return config
    }
    
    func forceClear() {
        safePool.clearAll()
        
        //清除当前展示
        if isShown {
            dismissPopupView(force: true, canContinue: false)
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
}

/// show  & dismiss
extension SMPoolCore {
    private func showPopupView() {
        guard let top = safePool.top() as? SMPopupInterpreter else { return }
        currentInterperter = top

        safePool.pop()
        
        isShown = top.show()
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
            
            //如果pool不为空, 展示下一个
            if canContinue && !self.safePool.isEmpty() {
                self.showPopupView()
            }
        }
    }
    
    private func checkUselessPopup() {
        guard let currentInterperter = currentInterperter else { return }
        
        //如果当前Interperter 的 popupView 不存在, Interperter 置为 nil
        guard let currentPopup = currentInterperter.popupView else {
            self.currentInterperter = nil
            isShown = false
            return
        }
        //如果当前popupView没在Window上, 视为无主视图删除
        var nextSuper = currentPopup.superview
        while nextSuper != nil {
            if let nextSuper = nextSuper, nextSuper is UIWindow {
                return
            }
            nextSuper = nextSuper?.superview
        }
        self.currentInterperter = nil
        isShown = false
    }
}
