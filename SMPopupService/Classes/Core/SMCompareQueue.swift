//
//  SMCompareQueue.swift
//  PopupTest
//
//  Created by 董德富 on 2023/9/5.
//

import Foundation

class SMCompareQueue {
    
    private var queue: [Any] = []
    private let compare: (_ obj1: Any, _ obj2: Any) -> Bool
    
    init(compare: @escaping (_: Any, _: Any) -> Bool) {
        self.compare = compare
    }
    
    func push(_ element: Any) {
        queue.append(element)
        guard queue.count >= 2 else { return }
        
        var j = queue.count - 2
        while j >= 0 && compare(queue[j], element) {
            queue.swapAt(j+1, j)
            j -= 1
        }
        queue[j+1] = element
    }
    
    func pop() {
        if !isEmpty() {
            queue.removeFirst()
        }
    }
    
    func top() -> Any? {
        if let first = queue.first {
            return first
        }
        return nil
    }
    
    func isEmpty() -> Bool {
        return queue.isEmpty
    }
    
    func clear() {
        queue.removeAll()
    }
    
    func length() -> Int {
        return queue.count
    }
    
    func push(elements: [Any]) {
        elements.forEach { push($0) }
//        queue.append(contentsOf: with)
//        queue.sort(by: {compare($0, $1)})
    }
    
    func allObjects() -> [Any] {
        return queue
    }
}
