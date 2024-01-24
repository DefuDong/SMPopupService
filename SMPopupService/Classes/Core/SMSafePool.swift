//
//  SMSafePool.swift
//  PopupTest
//
//  Created by 董德富 on 2023/9/5.
//

import Foundation

class SMSafePool {
    
    init(queue: DispatchQueue?) {
        self.queue = queue ?? DispatchQueue(label: "Popup.Queue", attributes: .concurrent)
    }
    
    private let pool: SMCompareQueue = SMCompareQueue { obj1, obj2 in
        guard let p1 = (obj1 as? SMPopupInterpreter)?.priority,
              let p2 = (obj2 as? SMPopupInterpreter)?.priority else { return true }
        return p1 <= p2
    }
//    let pool: SMPriorityQueue = SMPriorityQueue { obj1, obj2 in
//        guard let p1 = (obj1 as? SMPopupInterpreter)?.priority,
//              let p2 = (obj2 as? SMPopupInterpreter)?.priority else { return true }
//        return p1 >= p2
//    }

    /// 展示队列
    private let queue: DispatchQueue

    func isEmpty() -> Bool {
        pool.isEmpty()
    }
    
    func push(_ inter: SMPopupInterpreter) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.pool.push(inter)
        }
    }
    
    func pop() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.pool.pop()
        }
    }
    
    func top() -> Any? {
        var result: Any?
        
        queue.sync { [weak self] in
            guard let self = self else { return }
            result = self.pool.top()
        }
            
        return result
    }
    
    func clear(level: SMPopupLevel) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            //查找池子里是否有相同level, 有则过滤掉
            if !self.pool.isEmpty() {
                let all = self.pool.allObjects()
                var resultArr: [Any] = []
                
                all.forEach { item in
                    if let config = (item as? SMPopupInterpreter)?.config,
                        config.level != level {
                        resultArr.append(item)
                    }
                }
                
                self.pool.clear()
                self.pool.push(elements: resultArr)
            }
        }
    }
    
    func clear(identifier: SMPopupIdentifier) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            //查找池子里是否有相同id, 有则过滤掉
            if !self.pool.isEmpty() {
                let all = self.pool.allObjects()
                var resultArr: [Any] = []
                
                all.forEach { item in
                    if let config = (item as? SMPopupInterpreter)?.config,
                        config.identifier != identifier {
                        resultArr.append(item)
                    }
                }
                
                self.pool.clear()
                self.pool.push(elements: resultArr)
            }
        }
    }
    
    func clearAll() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            //清除队列
            if !self.pool.isEmpty() {
                self.pool.clear()
            }
        }
    }
}
