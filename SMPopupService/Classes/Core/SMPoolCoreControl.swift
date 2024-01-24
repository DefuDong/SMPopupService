//
//  SMPoolCoreControl.swift
//  PopupTest
//
//  Created by 董德富 on 2023/9/5.
//

import Foundation

class SMPoolCoreControl: NSObject {
    static let instance: SMPoolCoreControl = SMPoolCoreControl()
    
    /// 放入队列并开始展示
    /// - Parameter inter: 弹窗
    func run(_ inter: SMPopupInterpreter) {
        runMain {
            self.core(inter).run(inter)
        }
    }
    
    /// 消除当前弹窗
    func exit(animate: Bool = true,
              identifier: SMPopupIdentifier? = nil,
              queue: SMPopupQueueType? = nil,
              complete: (() -> Void)? = nil) {
        runMain {
            self.core(queue: queue).exit(animate: animate, identifier: identifier, complete: complete)
        }
    }
        
    func pauseShow(_ queue: SMPopupQueueType? = nil) {
        runMain {
            self.core(queue: queue).pauseShow()
        }
    }
    
    func continueShow(_ queue: SMPopupQueueType? = nil) {
        runMain {
            self.core(queue: queue).continueShow()
        }
    }
    
    func suspend(_ queue: SMPopupQueueType? = nil) {
        runMain {
            self.core(queue: queue).suspend()
        }
    }
    
    func recover(_ queue: SMPopupQueueType? = nil) {
        runMain {
            self.core(queue: queue).recover()
        }
    }
    
    func clearPopupView(level: SMPopupLevel, _ queue: SMPopupQueueType? = nil) {
        runMain {
            self.core(queue: queue).clearPopupView(level: level)
        }
    }
    
    func clearPopupView(identifier: SMPopupIdentifier, _ queue: SMPopupQueueType? = nil) {
        runMain {
            self.core(queue: queue).clearPopupView(identifier: identifier)
        }
    }
    
    func isShowing(_ queue: SMPopupQueueType? = nil) -> Bool {
        return core(queue: queue).isShowing
    }

    func isShowing(identifier: SMPopupIdentifier, _ queue: SMPopupQueueType? = nil) -> Bool {
        return core(queue: queue).isShowing(identifier: identifier)
    }
    
    func forceClear(_ queue: SMPopupQueueType? = nil) {
        runMain {
            self.core(queue: queue).forceClear()
        }
    }
    
    func currentItem(_ queue: SMPopupQueueType? = nil) -> SMPopupConfig? {
        return core(queue: queue).currentItem()
    }
    
    //默认只发送主队列
    func sendEvent(event: SMPopupEvent, _ queue: SMPopupQueueType? = nil) {
        core(queue: queue).sendEvent(event)
    }
    
    func updateLayout(identifier: SMPopupIdentifier? = nil, animate: Bool = true, _ queue: SMPopupQueueType? = nil) {
        runMain {
            self.core(queue: queue).updateLayout(identifier: identifier, animate: animate)
        }
    }
    
    private override init() {
        super.init()
    }

    private lazy var mainCore: SMPoolCore = SMPoolCore(queue: queue)
    private lazy var coexistenceCore: SMPoolCore = SMPoolCore(queue: queue)
    /// 展示队列
    private let queue: DispatchQueue = DispatchQueue(label: "Popup.Queue", attributes: .concurrent)

    
    private func core(_ inter: SMPopupInterpreter) -> SMPoolCore {
        return core(queue: inter.config.queue)
    }
    
    private func core(queue: SMPopupQueueType? = nil) -> SMPoolCore {
        if let queue = queue {
            return queue == .default ? mainCore : coexistenceCore
        }
        return mainCore
    }
    
    private func runMain(_ work: @escaping @convention(block) () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async { work() }
        }
    }
}
