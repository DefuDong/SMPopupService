//
//  SMPopupConfig.swift
//  PopupTest
//
//  Created by 董德富 on 2023/8/31.
//

import Foundation
import UIKit

@objcMembers
public class SMPopupConfig: NSObject {
    
     public convenience init(sceneStyle: SMPopupScene) {
        self.init()
        self.scene = sceneStyle
        switch sceneStyle {
        case .center:
            cornerRadius = 0
            rectCorners = .allCorners
            showAnimationStyle = .bubble
            dismissAnimationStyle = .fade
        case .sheet:
            cornerRadius = 10
            rectCorners = [.topLeft, .topRight]
        case .push:
            //默认自带上滑关闭手势
            isTopBarPanDismiss = true
            //默认不展示蒙层
            isHiddeBackgroundView = true
            //默认取消点击消失手势
            isClickCoverDismiss = false
            //默认5s自动消失
            dismissDuration = 5
            
            cornerRadius = 8
            rectCorners = .allCorners
        }
    }
    
    /// 弹窗唯一标识
    public var identifier: SMPopupIdentifier?
    
    /// 优先级, 数字越大优先级越高 (默认0)  取值 0 - 1000
    public var priority: SMPopupPriority = 0 {
        didSet {
            assert(priority < 1000 && priority >= 0, "priority is out of edge")
        }
    }
    
    ///  弹窗级别, 默认default (用于优先级分层)
    ///  maxAndImmediately 是否立即展示 (谨慎使用).
    /// 如果true, 会忽视掉level和priority配置, 不加入队列排序. dismiss当前展示的弹窗并且立即展示 (如果当前为pause状态,会先加入队列)
    /// 如果已存在maxAndImmediately弹窗, 会加入到队列中,设置最高优先级,并且按照加入顺序展示
    public var level: SMPopupLevel = .default
    
    ///  展示队列, 默认default (coexistence共存队列，仅建议SMPopupScene.push可加入此队列)
    public var queue: SMPopupQueueType = .default

    /// 弹窗场景风格
    public var sceneStyle: SMPopupScene { scene }
        
    /// 点击弹窗背景（弹窗内容之外的区域）弹窗是否消失
    public var isClickCoverDismiss: Bool = true
    
    /// 弹窗的容器视图，默认是keywindow
    public var containerView: UIView?
    
    /// 弹窗展示时长 设置后会在设定时间结束后自动dismiss,  <=0 不设置不会自动消失
    public var dismissDuration: TimeInterval = 0
    
    /// 出现动画, scene = .center 才会生效
    public var showAnimationStyle: SMPopupShowAnimationStyle = .fade
    
    /// 消失动画, scene = .center 才会生效
    public var dismissAnimationStyle: SMPopupDismissAnimationStyle = .fade
    
    /// 弹窗内容圆角方向,默认UIRectCornerAllCorners,当cornerRadius>0时生效
    public var rectCorners: UIRectCorner = .allCorners
    
    /// 弹窗内容圆角大小
    public var cornerRadius: CGFloat = 0
    
    /// 顶部通知条支持上滑关闭 默认false
    public var isTopBarPanDismiss: Bool = false
    
    ///  是否隐藏背景遮罩
    public var isHiddeBackgroundView: Bool = false
    
    /// 遮罩背景颜色
    public var backgroundColor: UIColor = .black.withAlphaComponent(0.5)
    
    private override init() {
        super.init()
    }
    
    private var scene: SMPopupScene = .center
}

