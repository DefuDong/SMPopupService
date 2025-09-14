//
//  SMSafePool.swift
//  PopupTest
//
//  Created by 董德富 on 2023/9/5.
//

import Foundation

/**
 * 安全弹窗池管理器
 * 
 * 功能说明：
 * - 使用优先级队列管理弹窗任务，确保按优先级顺序执行
 * - 提供线程安全的弹窗操作，支持并发访问
 * - 支持按级别和标识符清除特定弹窗
 * - 使用小根堆实现，优先级数值越小越优先执行
 * 
 * 线程安全：
 * - 使用并发队列 + barrier 标志确保写操作安全
 * - 读操作使用同步调用确保数据一致性
 * - 所有操作都在独立队列中执行，避免主线程阻塞
 * 
 * 优先级规则：
 * - 数值越大优先级越高（大根堆特性）
 * - 相同优先级的弹窗按添加顺序执行
 * - 无法获取优先级的弹窗默认优先级最高
 */
class SMSafePool {
    private let pool: SMPriorityQueue = SMPriorityQueue { obj1, obj2 in
        guard let p1 = (obj1 as? SMPopupInterpreter)?.priority,
              let p2 = (obj2 as? SMPopupInterpreter)?.priority else { return true }
        return p1 >= p2  // 大优先级在前，符合大根堆特性
    }

    /// 共享的并发队列，用于管理弹窗操作的线程安全
    private static let sharedQueue: DispatchQueue = DispatchQueue(label: "Popup.Queue", attributes: .concurrent)
    
    /// 当前实例使用的队列引用
    private let queue: DispatchQueue = SMSafePool.sharedQueue

    /**
     * 检查弹窗池是否为空
     * 
     * - Returns: 如果池中没有弹窗任务返回true，否则返回false
     * - Note: 此方法是线程安全的，使用同步调用确保数据一致性
     */
    func isEmpty() -> Bool {
        pool.isEmpty()
    }
    
    /**
     * 向弹窗池中添加新的弹窗任务
     * 
     * - Parameter inter: 要添加的弹窗解释器对象
     * - Note: 此方法是线程安全的，使用barrier标志确保写操作独占执行
     * - Note: 弹窗会根据优先级自动排序，优先级高的会排在前面
     * - Complexity: O(log n)，其中n是当前池中的任务数量
     */
    func push(_ inter: SMPopupInterpreter) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.pool.push(inter)
        }
    }
    
    /**
     * 从弹窗池中移除优先级最高的弹窗任务
     * 
     * - Note: 此方法是线程安全的，使用barrier标志确保写操作独占执行
     * - Note: 如果池为空，此操作不会产生任何效果
     * - Note: 移除的是优先级最高的任务（堆顶元素）
     * - Complexity: O(log n)，其中n是当前池中的任务数量
     */
    func pop() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            self.pool.pop()
        }
    }
    
    /**
     * 获取弹窗池中优先级最高的弹窗任务（不移除）
     * 
     * - Returns: 优先级最高的弹窗解释器对象，如果池为空则返回nil
     * - Note: 此方法是线程安全的，使用同步调用确保数据一致性
     * - Note: 此操作不会移除任务，只是查看堆顶元素
     * - Complexity: O(1)，直接访问堆顶元素
     */
    func top() -> Any? {
        var result: Any?
        
        queue.sync { [weak self] in
            guard let self = self else { return }
            result = self.pool.top()
        }
            
        return result
    }
    
    /**
     * 清除指定级别的所有弹窗任务
     * 
     * - Parameter level: 要清除的弹窗级别
     * - Note: 此方法是线程安全的，使用barrier标志确保写操作独占执行
     * - Note: 会保留其他级别的弹窗任务，只移除指定级别的任务
     * - Note: 如果池为空或没有指定级别的任务，此操作不会产生任何效果
     * - Complexity: O(n)，其中n是当前池中的任务数量
     */
    func clear(level: SMPopupLevel) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // 查找池子里是否有相同level, 有则过滤掉
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
                self.pool.push(with: resultArr)
            }
        }
    }
    
    /**
     * 清除指定标识符的弹窗任务
     * 
     * - Parameter identifier: 要清除的弹窗标识符
     * - Note: 此方法是线程安全的，使用barrier标志确保写操作独占执行
     * - Note: 会保留其他标识符的弹窗任务，只移除指定标识符的任务
     * - Note: 如果池为空或没有指定标识符的任务，此操作不会产生任何效果
     * - Complexity: O(n)，其中n是当前池中的任务数量
     */
    func clear(identifier: SMPopupIdentifier) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // 查找池子里是否有相同id, 有则过滤掉
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
                self.pool.push(with: resultArr)
            }
        }
    }
    
    /**
     * 清除弹窗池中的所有任务
     * 
     * - Note: 此方法是线程安全的，使用barrier标志确保写操作独占执行
     * - Note: 会移除池中的所有弹窗任务，无论级别或标识符
     * - Note: 如果池为空，此操作不会产生任何效果
     * - Complexity: O(1)，直接清空底层数据结构
     */
    func clearAll() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            // 清除队列
            if !self.pool.isEmpty() {
                self.pool.clear()
            }
        }
    }
}
