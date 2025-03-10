//
//  SMPopupConst.swift
//  PopupTest
//
//  Created by 董德富 on 2023/8/31.
//

import Foundation
import UIKit

public typealias SMPopupPriority = Int
public typealias SMPopupIdentifier = String

public typealias SMPopupEventBlock = (_ popupView: UIView, _ config: SMPopupConfig, _ event: SMPopupEvent) -> Void
public typealias SMPopupSubcribeCallback = (_ type: SMPopupSubcribeType, _ object: Any?) -> Void

/// 展示动画 (SMPopupScene.center才会生效)
@objc
public enum SMPopupShowAnimationStyle: Int {
    case fade           //渐隐渐变出现
    case topFall        //顶部降落
    case bottomRise     //底部升起
    case bubble         //比例动画
    case none           //无
}

///  消失动画, center 才会生效
@objc
public enum SMPopupDismissAnimationStyle: Int {
    case fade       //渐隐
    case bottomFall //底部降落
    case topRise    //顶部升起
    case none       //无
}

/// 弹窗场景类型
@objc
public enum SMPopupScene: Int {
    case center         //中心展示
    case sheet          //底部半屏弹窗 (动画类型不可定制)
    case push           //顶部通知条 (动画类型不可定制)
}

/// 弹窗分级
@objc
public enum SMPopupLevel: Int {
    case `default`
    case low
    case high
    case maxAndImmediately
}

/// 自定义事件类型
@objc
public enum SMPopupEventType: Int {
    case lifeCycle  //生命周期
    case custom     //自定义事件
}

/// 检查弹窗是否可以展示
@objc
public enum SMPopupCheckResult: Int {
    case show               //展示
    case pause              //暂停(什么都不做) 要记得自己恢复队列(continue)⚠️
    case discardedContinue  //丢弃并继续展示下一个
    case discardedPause     //丢弃并暂停, 要记得自己恢复队列(continue)⚠️
}

/// 弹窗订阅类型
@objc
public enum SMPopupSubcribeType: Int {
    case empty //队列清空
}
