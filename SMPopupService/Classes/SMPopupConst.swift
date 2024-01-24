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

///  加入的展示队列, 默认default, coexistence为共存队列
@objc
public enum SMPopupQueueType: Int {
    case `default`      //默认队列
    case coexistence    //共存队列
}

/// 展示动画 (SMPopupScene.center才会生效)
@objc
public enum SMPopupShowAnimationStyle: Int {
    case fade           //渐隐渐变出现
    case topFall        //顶部降落
    case bottomRise     //底部升起
    case bubble         //比例动画
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
