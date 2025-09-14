//
//  SMPopupInterpreter.swift
//  PopupTest
//
//  Created by 董德富 on 2023/8/31.
//

import Foundation
import UIKit

/**
 * 弹窗解释器类
 * 
 * 功能说明：
 * - 负责弹窗的显示、隐藏、动画和生命周期管理
 * - 处理弹窗的布局、样式和交互逻辑
 * - 支持自定义动画、DataSource和Delegate
 * - 管理弹窗的定时器、手势和事件回调
 * 
 * 架构设计：
 * - 作为弹窗的核心控制器，封装了所有弹窗操作
 * - 通过DataSource模式支持动态创建弹窗视图
 * - 通过Delegate模式提供生命周期回调
 * - 支持事件系统，可以发送和接收自定义事件
 * 
 * 使用场景：
 * - 队列管理的弹窗：通过SMPoolCore调用
 * - 单独弹窗：通过SMPopupContainer包装使用
 * - 自定义弹窗：实现DataSource和Delegate协议
 * 
 * 线程安全：
 * - 所有UI操作都在主线程执行
 * - 定时器和动画操作自动切换到主线程
 * - 事件回调在主线程执行
 */
class SMPopupInterpreter: NSObject {
    
    /// 弹窗配置对象
    /// - Note: 包含弹窗的所有配置信息，如样式、动画、优先级等
    let config: SMPopupConfig
    
    /// 弹窗视图
    /// - Note: 实际的弹窗UI视图，可能由view参数或dataSource创建
    var popupView: UIView?
    
    /// 事件回调块
    /// - Note: 用于发送自定义事件，支持弹窗与外部通信
    var eventBlock: SMPopupEventBlock?
    
    /// 消失回调(定时器/手势/背景点击)
    /// - Note: 当弹窗因定时器、手势或背景点击而消失时调用
    var dismissCalledBlock: (() -> Void)?
    
    /// 弹窗异常消失回调
    /// - Note: 当弹窗不在当前视图层及展示时调用，比如控制器右滑等异常情况
    var abnormalDismissBlock: (() -> Void)?

    /// 数据源协议对象
    /// - Note: 用于动态创建弹窗视图和自定义布局
    private var dataSource: SMPopupViewDataSource?
    
    /// 代理协议对象
    /// - Note: 用于接收弹窗生命周期回调
    private var delegate: SMPopupViewDelegate?

    /// 初始化弹窗解释器
    /// - Parameters:
    ///   - config: 弹窗配置对象，包含样式、动画、优先级等配置
    ///   - popupView: 弹窗视图，如果提供则直接使用
    ///   - dataSource: 数据源协议，用于动态创建弹窗视图
    ///   - delegate: 代理协议，用于接收生命周期回调
    /// - Note: popupView和dataSource二选一，不能同时为nil
    init(config: SMPopupConfig, popupView: UIView? = nil, dataSource: SMPopupViewDataSource? = nil, delegate: SMPopupViewDelegate? = nil) {
        self.config = config
        self.popupView = popupView
        self.dataSource = dataSource
        self.delegate = delegate
    }
    
    /// 显示弹窗
    /// - Parameter isSingle: 是否为单独弹窗，单独弹窗会设置popupViewProtocol
    /// - Returns: 是否显示成功
    /// - Note: 此方法会执行完整的弹窗显示流程，包括视图创建、布局、动画等
    func show(_ isSingle: Bool = false) -> Bool {
        // 获取弹窗视图（从参数或dataSource创建）
        popupView = getPopupView()
        
        // 如果是单独弹窗，设置协议对象用于外部控制
        if isSingle {
            popupView?.popupViewProtocol = self
        }
        
        // 验证弹窗视图是否存在
        guard let popupView = popupView else { return false }
        
        // 获取容器视图（配置的容器或主窗口）
        guard let container = config.containerView ?? UIApplication.shared.getKeyWindow() else { return false }
        
        // 生命周期回调：弹窗即将出现
        realDelegate()?.popupWillAppear?()
        sendEvent(SMPopupEvent.lifeCycleEvent(scene: SMPopupEvent.SMPopupViewWillAppear))
        
        var backFrame = container.bounds
        if backFrame.size == .zero {
            backFrame = UIScreen.main.bounds
        }
        
        backView.frame = backFrame
        backView.backgroundColor = config.isHiddeBackgroundView ? .clear : config.backgroundColor
        backView.hideMask = config.isHiddeBackgroundView
        backView.addSubview(popupView)
        
        addGesture()
        // keyboard

        //添加背景视图
        if backView.superview == nil {
            container.addSubview(backView)
            container.bringSubviewToFront(backView)
        }
        //布局
        customLayout()

        configCorners()
        popAnimated { _ in
            //lify cycle
            self.realDelegate()?.popupDidAppear?()
            self.sendEvent(SMPopupEvent.lifeCycleEvent(scene: SMPopupEvent.SMPopupViewDidAppear))
        }
        
        startTimer()
        return true
    }
    
    func dismiss(_ force: Bool = false, completion: (() -> Void)? = nil) {
        guard let popupView = popupView, let _ = popupView.superview else { return }

        //lify cycle
        realDelegate()?.popupWillDisappear?()
        sendEvent(SMPopupEvent.lifeCycleEvent(scene: SMPopupEvent.SMPopupViewWillDisappear))

        let completeCall: (() -> Void) = { [weak self] in
            self?.stopTimer()
            
            self?.backView.removeFromSuperview()
            //lify cycle
            self?.realDelegate()?.popupDidDisappear?()
            self?.sendEvent(SMPopupEvent.lifeCycleEvent(scene: SMPopupEvent.SMPopupViewDidDisappear))
            completion?()
        }
        
        guard !force else {
            completeCall()
            return
        }
        
        //自定义动画
        if checkIsCustomDismissAnimation(completion: { _ in completeCall() }) { return }
        
        let position = popupView.layer.position
        let frame = originalFrame

        switch config.sceneStyle {
        case .sheet:
            UIView.animate(withDuration: duration) {
                popupView.layer.position = CGPoint(x: position.x, y: CGRectGetMaxY(frame) + CGRectGetHeight(frame)*0.5)
            } completion: { _ in
                completeCall()
            }
        case .push:
            UIView.animate(withDuration: duration) {
                popupView.layer.position = CGPoint(x: position.x, y: -CGRectGetHeight(frame)*0.5)
            } completion: { _ in
                completeCall()
            }
        case .center:
            dismissCenterAnimate(style: config.dismissAnimationStyle, complete: completeCall)
        }
    }
    
    func sendEvent(_ event: SMPopupEvent) {
        if let pop = getPopupView() {
            eventBlock?(pop, config, event)
        }
    }
    
    func updateLayout(animate: Bool = true) {
        guard let popupView = popupView else { return }
        
        var isAutoLayout = false
        if let dataSource = realDataSource(),
            dataSource.responds(to: #selector(SMPopupViewDataSource.layout(superView:))) {
            isAutoLayout = true
        }
        
        if animate {
            if isAutoLayout {
                UIView.animate(withDuration: duration) {
                    self.backView.layoutIfNeeded()
                } completion: { _ in
                    self.originalFrame = popupView.frame
                    self.configCorners()
                }
            } else {
                UIView.animate(withDuration: duration) {
                    self.originalFrame = popupView.frame
                } completion: { _ in
                    self.configCorners()
                }
            }
        } else {
            if isAutoLayout {
                backView.setNeedsLayout()
                backView.layoutIfNeeded()
            }
            originalFrame = popupView.frame
            configCorners()
        }
    }
    
    ///  真实优先值
    var priority: SMPopupPriority {
        var weight: Int = 0
        
        switch config.level {
        case .low:
            weight = 1
        case .default:
            weight = 10001
        case .high:
            weight = 20001
        case .maxAndImmediately:
            weight = 100000
        }
        return config.priority + weight
    }
    
    private lazy var backView: SMPopupMaskView = {
        let view = SMPopupMaskView { [weak self] in
            if let _ = self?.popupView?.popupViewProtocol { //如果是单独弹出的弹窗, 直接dismiss
                self?.dismiss(true)
            } else {
                self?.abnormalDismissBlock?()
            }
        }
        return view
    }()
    //存储弹窗原始frame
    private var originalFrame: CGRect = .zero
    
    private let duration = 0.25
    
    private var timer: Timer? //定时器
    private var dismissTime: TimeInterval = 0 //倒计时
}

//动画相关
extension SMPopupInterpreter {
    private func popAnimated(completion: @escaping (Bool) -> Void) {
        guard let popupView = popupView else { return }

        let duration = 0.25
        
        //背景动画
        if backgroundColor() != .clear {
            backView.backgroundColor = backgroundColor(alpha: 0)
            UIView.animate(withDuration: duration) { [weak self] in
                self?.backView.backgroundColor = self?.backgroundColor()
            }
        }
        
        //自定义动画
        if checkIsCustomShowAnimation(completion: completion) { return }
        
        //
        popupView.alpha = 1
        let startPosition = CGPoint(x: CGRectGetMidX(originalFrame), y: CGRectGetMidY(originalFrame))
        let position = popupView.layer.position
        
        switch config.sceneStyle {
        case .sheet:
            popupView.layer.position = CGPoint(x: position.x, y: CGRectGetMaxY(originalFrame) + CGRectGetHeight(originalFrame)*0.5)
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 1,
                           options: .curveEaseOut) {
                popupView.layer.position = startPosition
            } completion: { finish in
                completion(finish)
            }
        case .push:
            popupView.layer.position = CGPoint(x: position.x, y: -CGRectGetHeight(originalFrame)*0.5)
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 1,
                           options: .curveEaseOut) {
                popupView.layer.position = startPosition
            } completion: { finish in
                completion(finish)
            }
        case .center:
            popCenterAnimate(completion: completion)
        }
    }
    
    private func popCenterAnimate(completion: @escaping (Bool) -> Void) {
        guard let popupView = popupView else { return }
        let position = popupView.layer.position

        switch config.showAnimationStyle {
        case .fade:
            fadeAnimate(show: true, completion: completion)
        case .topFall:
            popupView.layer.position = CGPoint(x: position.x, y: CGRectGetMidY(originalFrame) - CGRectGetHeight(originalFrame) * 0.5)
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 1,
                           options: .curveEaseOut) {
                popupView.layer.position = position
            } completion: { finish in
                completion(finish)
            }
        case .bottomRise:
            popupView.layer.position = CGPoint(x: position.x, y: CGRectGetMaxY(originalFrame) + CGRectGetHeight(originalFrame) * 0.5)
            UIView.animate(withDuration: duration,
                           delay: 0,
                           usingSpringWithDamping: 1,
                           initialSpringVelocity: 1,
                           options: .curveEaseOut) {
                popupView.layer.position = position
            } completion: { finish in
                completion(finish)
            }
        case .bubble:
            fadeAnimate(show: true, completion: completion)
            bubbleAnimate(popupView.layer)
        case .none:
            completion(true)
        }
    }
    
    private func fadeAnimate(show: Bool, completion: @escaping (Bool) -> Void) {
        guard let popupView = popupView else { return }
        if show {
            if backgroundColor() != .clear {
                backView.backgroundColor = backgroundColor(alpha: 0)
            }
            popupView.alpha = 0
            UIView.animate(withDuration: duration) { [weak self] in
                self?.backView.backgroundColor = self?.backgroundColor()
                popupView.alpha = 1
            } completion: { finsh in
                completion(finsh)
            }
        } else {
            UIView.animate(withDuration: duration) { [weak self] in
                self?.backView.backgroundColor = self?.backgroundColor(alpha: 0)
                popupView.alpha = 0
            } completion: { finish in
                completion(finish)
            }
        }
    }

    private func bubbleAnimate(_ layer: CALayer) {
        let animate = CAKeyframeAnimation.init(keyPath: "transform")
        animate.duration = duration
        animate.values = [NSValue.init(caTransform3D: CATransform3DMakeScale(1.1, 1.1, 1.0)),
                          NSValue.init(caTransform3D: CATransform3DIdentity)]
        animate.timingFunctions = [CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeInEaseOut),
                                   CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeInEaseOut)]
        layer.add(animate, forKey: nil)
    }
    
    private func backgroundColor(alpha: CGFloat? = nil) -> UIColor {
        if config.isHiddeBackgroundView { return .clear }
        if config.backgroundColor == .clear { return .clear }
        if let alpha = alpha { return config.backgroundColor.withAlphaComponent(alpha) }
        return config.backgroundColor
    }
    
    private func dismissCenterAnimate(style: SMPopupDismissAnimationStyle, complete: @escaping () -> Void) {
        guard let popupView = popupView else { return }
        let position = popupView.layer.position

        switch style {
        case .fade:
            fadeAnimate(show: false) { _ in
                complete()
            }
        case .topRise:
            let endPosition = CGPoint(x: position.x, y: -CGRectGetHeight(originalFrame) * 0.5)
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: .curveEaseIn) {
                popupView.layer.position = endPosition
                popupView.layer.opacity = 1
            } completion: { _ in
                complete()
            }
        case .bottomFall:
            var endY = CGRectGetMaxY(originalFrame) + CGRectGetHeight(originalFrame)
            if let superMaxY = popupView.superview?.frame.size.height {
                endY = superMaxY + CGRectGetHeight(originalFrame) * 0.5
            }
            let endPosition = CGPoint(x: position.x, y: endY)
            UIView.animate(withDuration: duration,
                           delay: 0,
                           options: .curveEaseIn) {
                popupView.layer.position = endPosition
                popupView.layer.opacity = 1
            } completion: { _ in
                complete()
            }
        case .none:
            complete()
        }
    }
}

extension SMPopupInterpreter: UIGestureRecognizerDelegate {
    private func configCorners() {
        guard let popupView = popupView, config.cornerRadius > 0 else { return }
        
        backView.layoutIfNeeded()
        let path = UIBezierPath.init(roundedRect: popupView.bounds,
                                     byRoundingCorners: config.rectCorners,
                                     cornerRadii: CGSize(width: config.cornerRadius, height: config.cornerRadius))
        let layer = CAShapeLayer()
        layer.frame = popupView.bounds
        layer.path = path.cgPath
        popupView.layer.mask = layer
    }
    
    private func addGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(backViewTap(_:)))
        tap.delegate = backView
        backView.addGestureRecognizer(tap)
        
        if config.isTopBarPanDismiss {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(backViewPan(_:)))
            tap.delegate = self
            backView.addGestureRecognizer(pan)
        }
    }
    
    @objc private func backViewTap(_ gesture: UIGestureRecognizer) {
        guard config.isClickCoverDismiss else { return }
        backView.endEditing(true)
        dismissCalledBlock?()
    }
    
    @objc private func backViewPan(_ gesture: UIPanGestureRecognizer) {
        guard let popupView = popupView else { return }
        
        /*
        let p = gesture.translation(in: popupView)
        let frame = originalFrame
        let position = popupView.layer.position

        if p.y < 0 {
            let offsetY = CGRectGetMidY(frame) - abs(p.y)
            popupView.layer.position = CGPoint(x: position.x, y: offsetY)
        } else {
            popupView.frame = frame
        }

        if gesture.state == .ended {
            //向上滑动了至少内容的一半高度，关闭弹窗
            if abs(p.y) >= frame.size.height / 2.0 {
                SMPoolCoreControl.instance.exit(model.queue)
            } else { //复原
                popupView.frame = frame
            }
        }
         */
        
        let offset = gesture.translation(in: popupView)
        var frame = popupView.frame
        var top = frame.origin.y + offset.y
                
        switch gesture.state {
        case .changed:
            if top >= UIScreen.p_safeTop() + 50 {
                top = UIScreen.p_safeTop() + 50
            }
            frame.origin.y = top
            popupView.frame = frame
        case .ended:
            dismissCalledBlock?()
        default:
            break
        }
        gesture.setTranslation(.zero, in: popupView)
    }
}

// dataSource & delegate
extension SMPopupInterpreter {
    private func getPopupView() -> UIView? {
        if popupView != nil { return popupView }
        if let popup = dataSource?.customPopupView?() { return popup }
        return nil
    }
    
    private func realDataSource() -> SMPopupViewDataSource? {
        if let popupView = popupView as? SMPopupViewDataSource {
            //如果 view 实现了 自定义协议
            return popupView
        } else if let dataSource = dataSource {
            //否则查找 dataSource 是否实现了自定义协议
            return dataSource
        }
        return nil
    }
    
    private func realDelegate() -> SMPopupViewDelegate? {
        if let popupView = popupView as? SMPopupViewDelegate {
            return popupView
        } else if let delegeta = delegate {
            return delegeta
        }
        return nil
    }
    
    //---------------------------------------------------------------------------------------------
    
    private func customLayout() {
        guard let popupView = popupView else { return }
        
        if let dataSource = realDataSource(),
            dataSource.responds(to: #selector(SMPopupViewDataSource.layout(superView:))) {
            dataSource.layout?(superView: backView)
        }
        
        backView.layoutIfNeeded()
        originalFrame = popupView.frame
    }
    
    private func checkIsCustomShowAnimation(completion: @escaping (Bool) -> Void) -> Bool {
        if let dataSource = realDataSource(),
           dataSource.responds(to: #selector(SMPopupViewDataSource.executeCustomShowAnimation(complete:))) {
            dataSource.executeCustomShowAnimation?(complete: completion)
            return true
        }
        return false
    }
    
    private func checkIsCustomDismissAnimation(completion: @escaping (Bool) -> Void) -> Bool {
        if let dataSource = realDataSource(),
           dataSource.responds(to: #selector(SMPopupViewDataSource.executeCustomDismissAnimation(complete:))) {
            dataSource.executeCustomDismissAnimation?(complete: completion)
            return true
        }
        return false
    }
}

// timer
extension SMPopupInterpreter {
    func startTimer() {
        guard config.dismissDuration > 0 && timer == nil else { return }
        
        dismissTime = config.dismissDuration
        stopTimer()
        
        // 使用 weak self 避免循环引用
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerLoop()
        }
        RunLoop.main.add(timer!, forMode: .common)
        timer?.fire()
    }
    
    func stopTimer() {
        if let t = timer {
            t.invalidate()
            timer = nil
        }
    }

    private func timerLoop() {
        if dismissTime < 1 {
            stopTimer()
            dismissCalledBlock?()
            return
        }
        
        dismissTime -= 1
    }
}

extension SMPopupInterpreter: SMPopupViewProtocol {
    func dismissSingle(_ animate: Bool, completion: (() -> Void)?) {
        dismiss(!animate, completion: completion)
    }
    
    func sendEventSingle(_ event: SMPopupEvent) {
        sendEvent(event)
    }
    
    func updateLayoutSingle(animate: Bool) {
        updateLayout(animate: animate)
    }
}
