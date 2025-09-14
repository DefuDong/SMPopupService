# SMPopupService API 使用说明

## 概述

SMPopupService 是一个功能强大的 iOS 弹窗管理框架，支持多种弹窗样式、优先级队列管理、动画效果和生命周期回调。该框架采用队列机制管理弹窗，确保弹窗按优先级顺序展示，避免弹窗冲突。

## 主要特性

- 🎯 **优先级队列管理** - 支持多级优先级，确保重要弹窗优先展示
- 🎨 **多种弹窗样式** - 支持中心弹窗、底部弹窗、顶部通知条
- ✨ **丰富的动画效果** - 内置多种展示和消失动画
- 🔄 **生命周期管理** - 完整的弹窗生命周期回调
- 🎛️ **灵活配置** - 支持自定义布局、动画、交互行为
- 🧵 **线程安全** - 内部使用线程安全队列管理
- 📱 **内存安全** - 智能内存管理，弹窗view持有配置对象
- 🏗️ **新架构** - 弹窗view自动管理生命周期，无需手动持有

## 快速开始

### 1. 基础使用

```swift
import SMPopupService

// 创建弹窗配置
let config = SMPopupConfig(sceneStyle: .center)
config.identifier = "my_popup"
config.priority = 100
config.dismissDuration = 3.0

// 创建弹窗视图
let popupView = UIView()
popupView.backgroundColor = .white
popupView.frame = CGRect(x: 0, y: 0, width: 300, height: 200)

// 展示弹窗
SMPopupService.standard.show(config: config, view: popupView)
```

### 2. 不同弹窗样式

#### 中心弹窗
```swift
let config = SMPopupConfig(sceneStyle: .center)
config.showAnimationStyle = .bubble
config.dismissAnimationStyle = .fade
config.cornerRadius = 10
config.backgroundColor = .black.withAlphaComponent(0.5)
```

#### 底部弹窗
```swift
let config = SMPopupConfig(sceneStyle: .sheet)
config.cornerRadius = 10
config.rectCorners = [.topLeft, .topRight]
```

#### 顶部通知条
```swift
let config = SMPopupConfig(sceneStyle: .push)
config.isTopBarPanDismiss = true
config.isHiddeBackgroundView = true
config.isClickCoverDismiss = false
config.dismissDuration = 5.0
```

## 详细 API 文档

### SMPopupService 主类

#### 静态实例

```swift
// 默认展示队列（推荐使用）
SMPopupService.standard

// 共存展示队列
SMPopupService.coexistence
```

#### 展示弹窗

##### 1. 基础展示方法
```swift
func show(config: SMPopupConfig, view: UIView)
```
- **参数**：
  - `config`: 弹窗配置对象
  - `view`: 弹窗视图
- **说明**：将弹窗加入队列，按优先级顺序展示

##### 2. 完整展示方法
```swift
func show(config: SMPopupConfig,
          view: UIView? = nil,
          dataSource: SMPopupViewDataSource? = nil,
          delegate: SMPopupViewDelegate? = nil,
          event: SMPopupEventBlock? = nil)
```
- **参数**：
  - `config`: 弹窗配置对象
  - `view`: 弹窗视图（可选）
  - `dataSource`: 数据源协议（可选）
  - `delegate`: 代理协议（可选）
  - `event`: 事件回调（可选）

##### 3. 单独展示方法（推荐）
```swift
class func showSingle(config: SMPopupConfig,
                     view: UIView? = nil,
                     dataSource: SMPopupViewDataSource? = nil,
                     delegate: SMPopupViewDelegate? = nil,
                     event: SMPopupEventBlock? = nil) -> SMPopupViewProtocol
```
- **返回值**：`SMPopupViewProtocol` 协议对象，用于控制弹窗
- **说明**：不加入队列，直接展示弹窗
- **新特性**：弹窗view自动持有配置对象，无需手动管理生命周期
- **使用方式**：
  ```swift
  // 基本使用（推荐）
  let _ = SMPopupService.showSingle(config: config, view: view)
  
  // 需要控制弹窗
  let container = SMPopupService.showSingle(config: config, view: view)
  container.dismissSingle(true)
  
  // 通过view控制
  view.popupContainer?.dismiss()
  view.popupViewProtocol?.sendEventSingle(event)
  ```

#### 控制弹窗

##### 消失弹窗
```swift
// 消失当前弹窗
func dismiss()

// 消失指定弹窗
func dismiss(animate: Bool = true,
             identifier: SMPopupIdentifier? = nil,
             complete: (() -> Void)? = nil)
```

##### 队列管理
```swift
// 暂停所有弹窗展示
func pause()

// 恢复弹窗展示
func `continue`()

// 清除指定级别的弹窗
func clear(level: SMPopupLevel)

// 清除指定标识符的弹窗
func clear(identifier: SMPopupIdentifier)

// 强制清除所有弹窗
func forceClearAll()
```

##### 状态查询
```swift
// 检查是否有弹窗在展示
func isShowing() -> Bool

// 检查指定弹窗是否在展示
func isShowing(identifier: SMPopupIdentifier) -> Bool

// 检查队列是否为空
func isEmpty() -> Bool

// 获取当前展示的弹窗配置
func currentItem() -> SMPopupConfig?

// 获取当前展示的弹窗视图
func currentPopupView(identifier: SMPopupIdentifier?) -> UIView?
```

##### 布局更新
```swift
func updateLayout(identifier: SMPopupIdentifier? = nil, animate: Bool = true)
```

##### 事件发送
```swift
func sendEvent(_ event: SMPopupEvent)
```

##### 监听器管理
```swift
func addListener(_ listener: AnyObject, callback: @escaping SMPopupSubcribeCallback)
```

### SMPopupConfig 配置类

#### 基础配置

```swift
// 弹窗唯一标识
var identifier: SMPopupIdentifier?

// 优先级 (0-1000)
var priority: SMPopupPriority = 0

// 弹窗级别
var level: SMPopupLevel = .default

// 弹窗场景风格
var sceneStyle: SMPopupScene

// 点击背景是否消失
var isClickCoverDismiss: Bool = true

// 容器视图
var containerView: UIView?

// 自动消失时长
var dismissDuration: TimeInterval = 0
```

#### 动画配置

```swift
// 出现动画样式
var showAnimationStyle: SMPopupShowAnimationStyle = .fade

// 消失动画样式
var dismissAnimationStyle: SMPopupDismissAnimationStyle = .fade
```

#### 外观配置

```swift
// 圆角方向
var rectCorners: UIRectCorner = .allCorners

// 圆角大小
var cornerRadius: CGFloat = 0

// 是否隐藏背景遮罩
var isHiddeBackgroundView: Bool = false

// 背景颜色
var backgroundColor: UIColor = .black.withAlphaComponent(0.5)
```

#### 交互配置

```swift
// 顶部通知条支持上滑关闭
var isTopBarPanDismiss: Bool = false

// 检查是否可以展示
var checkShowResult: (() -> SMPopupCheckResult) = { return .show }
```

### 枚举类型

#### SMPopupScene 弹窗场景
```swift
case center    // 中心展示
case sheet     // 底部半屏弹窗
case push      // 顶部通知条
```

#### SMPopupLevel 弹窗级别
```swift
case `default`           // 默认级别
case low                 // 低级别
case high                // 高级别
case maxAndImmediately   // 最高级别且立即展示
```

#### SMPopupShowAnimationStyle 展示动画
```swift
case fade        // 渐隐渐变出现
case topFall     // 顶部降落
case bottomRise  // 底部升起
case bubble      // 比例动画
case none        // 无动画
```

#### SMPopupDismissAnimationStyle 消失动画
```swift
case fade       // 渐隐
case bottomFall // 底部降落
case topRise    // 顶部升起
case none       // 无动画
```

#### SMPopupCheckResult 检查结果
```swift
case show               // 展示
case pause              // 暂停
case discardedContinue  // 丢弃并继续展示下一个
case discardedPause     // 丢弃并暂停
```

### 协议

#### SMPopupViewDataSource 数据源协议
```swift
// 提供自定义弹窗视图
@objc optional func customPopupView() -> UIView

// 执行自定义布局
@objc optional func layout(superView: UIView)

// 执行自定义展示动画
@objc optional func executeCustomShowAnimation(complete: @escaping (Bool) -> Void)

// 执行自定义消失动画
@objc optional func executeCustomDismissAnimation(complete: @escaping (Bool) -> Void)
```

#### SMPopupViewDelegate 代理协议
```swift
@objc optional func popupWillAppear()
@objc optional func popupDidAppear()
@objc optional func popupWillDisappear()
@objc optional func popupDidDisappear()
```

#### SMPopupViewProtocol 弹窗控制协议
```swift
// 消失弹窗
@objc func dismissSingle(_ animate: Bool, completion: (() -> Void)?)

// 发送事件
@objc func sendEventSingle(_ event: SMPopupEvent)

// 更新布局
@objc func updateLayoutSingle(animate: Bool)
```

## 使用示例

### 1. 简单弹窗（推荐使用showSingle）
```swift
let config = SMPopupConfig(sceneStyle: .center)
config.identifier = "simple_popup"
config.priority = 100

let popupView = UIView()
popupView.backgroundColor = .white
popupView.frame = CGRect(x: 0, y: 0, width: 300, height: 200)

// 新架构：弹窗view自动管理生命周期
let _ = SMPopupService.showSingle(config: config, view: popupView)

// 或者使用队列方式
SMPopupService.standard.show(config: config, view: popupView)
```

### 2. 新架构弹窗控制（推荐）
```swift
class MyViewController: UIViewController {
    
    func showPopup() {
        let config = SMPopupConfig(sceneStyle: .center)
        config.identifier = "new_architecture_popup"
        
        let popupView = UIView()
        popupView.backgroundColor = .white
        popupView.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        
        // 方式1：基本使用，无需持有返回对象
        let _ = SMPopupService.showSingle(config: config, view: popupView)
        
        // 方式2：需要控制弹窗时持有返回对象
        let container = SMPopupService.showSingle(config: config, view: popupView)
        
        // 3秒后自动关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            container.dismissSingle(true) {
                print("弹窗已关闭")
            }
        }
    }
    
    func controlPopupThroughView() {
        let popupView = UIView()
        popupView.backgroundColor = .systemBlue
        popupView.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        
        let config = SMPopupConfig(sceneStyle: .center)
        let _ = SMPopupService.showSingle(config: config, view: popupView)
        
        // 通过view控制弹窗
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 方式1：通过popupContainer
            popupView.popupContainer?.dismiss()
            
            // 方式2：通过popupViewProtocol
            popupView.popupViewProtocol?.sendEventSingle(
                SMPopupEvent.customEvent(name: "test", params: [:])
            )
        }
    }
}
```

### 3. 带生命周期的弹窗（队列方式）
```swift
class MyViewController: UIViewController, SMPopupViewDelegate {
    
    func showPopup() {
        let config = SMPopupConfig(sceneStyle: .center)
        config.identifier = "lifecycle_popup"
        
        let popupView = UIView()
        popupView.backgroundColor = .white
        popupView.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        
        SMPopupService.standard.show(
            config: config,
            view: popupView,
            delegate: self
        )
    }
    
    // MARK: - SMPopupViewDelegate
    func popupWillAppear() {
        print("弹窗即将出现")
    }
    
    func popupDidAppear() {
        print("弹窗已经出现")
    }
    
    func popupWillDisappear() {
        print("弹窗即将消失")
    }
    
    func popupDidDisappear() {
        print("弹窗已经消失")
    }
}
```

### 4. 自定义布局的弹窗
```swift
class CustomPopupViewController: UIViewController, SMPopupViewDataSource {
    
    func showCustomPopup() {
        let config = SMPopupConfig(sceneStyle: .center)
        config.identifier = "custom_popup"
        
        SMPopupService.standard.show(
            config: config,
            dataSource: self
        )
    }
    
    // MARK: - SMPopupViewDataSource
    func customPopupView() -> UIView {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }
    
    func layout(superView: UIView) {
        // 使用 SnapKit 或其他布局库进行布局
        view.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(300)
            make.height.equalTo(200)
        }
    }
}
```

### 5. 优先级队列管理
```swift
// 低优先级弹窗
let lowPriorityConfig = SMPopupConfig(sceneStyle: .center)
lowPriorityConfig.identifier = "low_priority"
lowPriorityConfig.priority = 10
lowPriorityConfig.level = .low

// 高优先级弹窗
let highPriorityConfig = SMPopupConfig(sceneStyle: .center)
highPriorityConfig.identifier = "high_priority"
highPriorityConfig.priority = 100
highPriorityConfig.level = .high

// 立即展示弹窗
let immediateConfig = SMPopupConfig(sceneStyle: .center)
immediateConfig.identifier = "immediate"
immediateConfig.level = .maxAndImmediately

// 按顺序添加，高优先级会先展示
SMPopupService.standard.show(config: lowPriorityConfig, view: lowPriorityView)
SMPopupService.standard.show(config: highPriorityConfig, view: highPriorityView)
SMPopupService.standard.show(config: immediateConfig, view: immediateView)
```

### 5. 事件系统
```swift
// 发送自定义事件
let customEvent = SMPopupEvent.customEvent(scene: "button_clicked", object: ["buttonId": "confirm"])
SMPopupService.standard.sendEvent(customEvent)

// 监听队列状态
SMPopupService.standard.addListener(self) { [weak self] type, object in
    switch type {
    case .empty:
        print("弹窗队列已清空")
    }
}
```

### 6. 新架构详解

#### 6.1 架构优势
- **自动生命周期管理**：弹窗view持有配置对象，无需手动管理
- **多种控制方式**：支持通过返回对象或view属性控制弹窗
- **内存安全**：当view被释放时，关联的容器自动释放
- **向后兼容**：保持原有API不变，支持所有现有功能

#### 6.2 核心组件
```swift
// SMPopupContainer - 弹窗容器类
public class SMPopupContainer: NSObject {
    // 持有SMPopupInterpreter和SMPopupConfig
    // 提供弹窗控制方法
    // 实现SMPopupViewProtocol协议
}

// UIView扩展 - 弹窗关联
extension UIView {
    @objc public var popupContainer: SMPopupContainer?
    @objc public var popupViewProtocol: SMPopupViewProtocol?
}
```

#### 6.3 使用方式对比
```swift
// 旧方式（需要手动管理）
let interpreter = SMPopupInterpreter(config: config, popupView: view)
// 必须持有interpreter，否则会被释放

// 新方式（自动管理）
let _ = SMPopupService.showSingle(config: config, view: view)
// 弹窗view自动持有配置对象，无需手动管理
```

#### 6.4 控制方式
```swift
// 方式1：通过返回的容器对象
let container = SMPopupService.showSingle(config: config, view: view)
container.dismissSingle(true)
container.sendEventSingle(event)

// 方式2：通过view属性
view.popupContainer?.dismiss()
view.popupViewProtocol?.sendEventSingle(event)

// 方式3：获取配置信息
let config = view.popupContainer?.getConfig()
let popupView = view.popupContainer?.getPopupView()
```

### 7. 队列管理
```swift
// 暂停所有弹窗
SMPopupService.standard.pause()

// 恢复弹窗展示
SMPopupService.standard.continue()

// 清除特定级别的弹窗
SMPopupService.standard.clear(level: .low)

// 清除特定弹窗
SMPopupService.standard.clear(identifier: "specific_popup")

// 强制清除所有弹窗
SMPopupService.standard.forceClearAll()
```

## 最佳实践

### 1. 推荐使用新架构
- **优先使用 `showSingle`**：自动管理生命周期，无需手动持有对象
- **避免手动管理**：不要直接创建 `SMPopupInterpreter`，使用 `showSingle` 方法
- **灵活控制**：需要控制弹窗时持有返回的容器对象

```swift
// ✅ 推荐：使用新架构
let _ = SMPopupService.showSingle(config: config, view: view)

// ✅ 需要控制时
let container = SMPopupService.showSingle(config: config, view: view)
container.dismissSingle(true)

// ❌ 不推荐：手动管理
let interpreter = SMPopupInterpreter(config: config, popupView: view)
```

### 2. 内存管理
- 使用 `[weak self]` 避免循环引用
- 及时移除不需要的监听器
- 避免在弹窗中持有强引用
- **新架构优势**：弹窗view自动管理生命周期，减少内存泄漏风险

### 3. 优先级设计
- 普通弹窗使用 `priority: 0-100`
- 重要弹窗使用 `priority: 100-500`
- 紧急弹窗使用 `level: .maxAndImmediately`

### 4. 标识符管理
- 使用有意义的标识符
- 避免重复使用相同标识符
- 考虑使用枚举管理标识符

### 5. 动画选择
- 中心弹窗推荐使用 `.bubble` 动画
- 底部弹窗使用默认动画
- 顶部通知条使用默认动画

### 6. 布局建议
- 使用 Auto Layout 进行布局
- 考虑不同屏幕尺寸的适配
- 测试横竖屏切换

## 注意事项

1. **线程安全**：所有 API 调用都应在主线程进行
2. **内存泄漏**：已修复 Timer 和闭包循环引用问题
3. **队列管理**：暂停后必须恢复，否则后续弹窗无法展示
4. **优先级范围**：priority 取值范围为 0-1000
5. **标识符唯一性**：相同标识符的弹窗会被覆盖
6. **新架构使用**：
   - 推荐使用 `showSingle` 方法，自动管理生命周期
   - 弹窗view会自动持有配置对象，无需手动管理
   - 支持通过 `popupContainer` 和 `popupViewProtocol` 属性控制弹窗
   - 当弹窗view被释放时，关联的容器会自动释放

## 版本更新

### 最新修复
- ✅ 修复 Timer 内存泄漏问题
- ✅ 修复闭包循环引用问题
- ✅ 优化 SMPriorityQueue 内存管理
- ✅ 添加异常检测深度限制
- ✅ 修复编译错误
- ✅ **新架构**：弹窗view持有配置对象，自动管理生命周期
- ✅ **showSingle优化**：无需手动持有返回对象，自动内存管理
- ✅ **多种控制方式**：支持通过返回对象或view属性控制弹窗

## 技术支持

如有问题或建议，请通过以下方式联系：
- 提交 Issue
- 发送邮件
- 查看源码注释

---

*本文档基于 SMPopupService v1.0.0 编写*
