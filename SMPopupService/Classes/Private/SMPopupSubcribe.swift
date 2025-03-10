//
//  SMPopupSubcribe.swift
//  SMPopupService
//
//  Created by 董德富 on 2025/3/6.
//

import Foundation

class SMPopupSubcribe {    
    private let lock = NSLock()
    private var subcribes: NSMapTable<AnyObject, CallbackWrapper> = NSMapTable(keyOptions: .weakMemory, valueOptions: .strongMemory)
    
    // 添加监听器
    func addListener(_ listener: AnyObject, callback: @escaping SMPopupSubcribeCallback) {
        lock.lock()
        let wrapper = CallbackWrapper(callback)
        subcribes.setObject(wrapper, forKey: listener)
        lock.unlock()
    }
    
    // 移除监听器
    func removeListener(_ listener: AnyObject) {
        lock.lock()
        subcribes.removeObject(forKey: listener)
        lock.unlock()
    }
    
    // 通知所有监听器
    func notifyListeners(_ type: SMPopupSubcribeType, _ objcet: Any? = nil) {
        lock.lock()
        for wrapper in subcribes.objectEnumerator() ?? NSEnumerator() {
            if let wrapper = wrapper as? CallbackWrapper {
                wrapper.callback(type, objcet)
            }
        }
        lock.unlock()
    }
    
    // 清理资源
    deinit {
        subcribes.removeAllObjects()
    }
    
    // 回调包装类
    private class CallbackWrapper {
        let callback: SMPopupSubcribeCallback
        init(_ callback: @escaping SMPopupSubcribeCallback) {
            self.callback = callback
        }
    }
}
