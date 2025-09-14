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
    private let pool: SMCompareQueue = SMCompareQueue { obj1, obj2 in
        guard let inter1 = obj1 as? SMPopupInterpreter,
              let inter2 = obj2 as? SMPopupInterpreter else {
            return false
        }
        return inter1.priority >= inter2.priority  // 大优先级在前
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
    var isEmpty: Bool {
        queue.sync { pool.isEmpty() }
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
            self?.pool.push(inter)
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
            self?.pool.pop()
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
    func top() -> SMPopupInterpreter? {
        queue.sync { pool.top() as? SMPopupInterpreter }
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
        clearFiltered { $0.config.level != level }
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
        clearFiltered { $0.config.identifier != identifier }
    }
    
    /**
     * 根据条件过滤并重建弹窗池
     * 
     * - Parameter predicate: 过滤条件，返回true表示保留该弹窗
     * - Note: 此方法是线程安全的，使用barrier标志确保写操作独占执行
     * - Complexity: O(n)，其中n是当前池中的任务数量
     */
    private func clearFiltered(where predicate: @escaping (SMPopupInterpreter) -> Bool) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self, !self.pool.isEmpty() else { return }
            
            let allObjects = self.pool.allObjects().compactMap { $0 as? SMPopupInterpreter }
            let filtered = allObjects.filter(predicate)
            self.pool.clear()
            if !filtered.isEmpty {
                self.pool.push(elements: filtered)
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
            self?.pool.clear()
        }
    }
    
    // MARK: - 便利方法
    
    /**
     * 获取弹窗池中的任务数量
     * 
     * - Returns: 当前池中的弹窗任务数量
     * - Note: 此方法是线程安全的，使用同步调用确保数据一致性
     */
    var count: Int {
        queue.sync { pool.length() }
    }
    
    /**
     * 批量添加弹窗任务
     * 
     * - Parameter interpreters: 要添加的弹窗解释器数组
     * - Note: 此方法是线程安全的，使用barrier标志确保写操作独占执行
     * - Complexity: O(n log n)，其中n是添加的任务数量
     */
    func push(_ interpreters: [SMPopupInterpreter]) {
        guard !interpreters.isEmpty else { return }
        
        queue.async(flags: .barrier) { [weak self] in
            self?.pool.push(elements: interpreters)
        }
    }
    
    /**
     * 检查是否存在指定级别的弹窗
     * 
     * - Parameter level: 要检查的弹窗级别
     * - Returns: 如果存在指定级别的弹窗返回true，否则返回false
     * - Note: 此方法是线程安全的，使用同步调用确保数据一致性
     */
    func contains(level: SMPopupLevel) -> Bool {
        queue.sync {
            let allObjects = pool.allObjects().compactMap { $0 as? SMPopupInterpreter }
            return allObjects.contains { $0.config.level == level }
        }
    }
    
    /**
     * 检查是否存在指定标识符的弹窗
     * 
     * - Parameter identifier: 要检查的弹窗标识符
     * - Returns: 如果存在指定标识符的弹窗返回true，否则返回false
     * - Note: 此方法是线程安全的，使用同步调用确保数据一致性
     */
    func contains(identifier: SMPopupIdentifier) -> Bool {
        queue.sync {
            let allObjects = pool.allObjects().compactMap { $0 as? SMPopupInterpreter }
            return allObjects.contains { $0.config.identifier == identifier }
        }
    }
    
    /**
     * 获取所有弹窗任务（用于调试）
     * 
     * - Returns: 当前池中所有弹窗任务的数组
     * - Note: 此方法是线程安全的，使用同步调用确保数据一致性
     * - Warning: 此方法仅用于调试，不应在生产环境中频繁调用
     */
    func allObjects() -> [SMPopupInterpreter] {
        queue.sync { pool.allObjects().compactMap { $0 as? SMPopupInterpreter } }
    }
}
