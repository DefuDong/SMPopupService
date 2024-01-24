//
//  SMPopupEvent.swift
//  PopupTest
//
//  Created by 董德富 on 2023/9/6.
//

import Foundation

@objcMembers
public class SMPopupEvent: NSObject {
    public typealias SMPopupEventScene = String
    public static let SMPopupViewWillAppear: SMPopupEventScene = "SMPopupViewWillAppear"
    public static let SMPopupViewDidAppear: SMPopupEventScene = "SMPopupViewDidAppear"
    public static let SMPopupViewWillDisappear: SMPopupEventScene = "SMPopupViewWillDisappear"
    public static let SMPopupViewDidDisappear: SMPopupEventScene = "SMPopupViewDidDisappear"

    /// 事件类型
    public let eventType: SMPopupEventType
    
    /// 场景类型
    public var eventScene: SMPopupEventScene?
    
    /// 需要透传的附加参数
    public var object: Any?
    
    public init(eventType: SMPopupEventType, eventScene: SMPopupEventScene? = nil, object: Any? = nil) {
        self.eventType = eventType
        self.eventScene = eventScene
        self.object = object
    }
    
    public static func lifeCycleEvent(scene: SMPopupEventScene) -> SMPopupEvent {
        return SMPopupEvent.init(eventType: .lifeCycle, eventScene: scene)
    }
    
    public static func customEvent(scene: SMPopupEventScene, object: Any?) -> SMPopupEvent {
        return SMPopupEvent.init(eventType: .custom, eventScene: scene, object: object)
    }
}
