//
//  ViewController.swift
//  PopupTest
//
//  Created by 董德富 on 2023/8/30.
//

import UIKit
import SMPopupService

public enum SMPopupQueueType: Int {
    case `default`      //默认队列
    case coexistence    //共存队列
}

class ViewController: UIViewController {
    
    let customService = SMPopupService()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        typealias ButtonItem = (title: String, sel: Selector)
        let buttonItems: [ButtonItem] = [("Center", #selector(button1Action)),
                                         ("Top", #selector(button2Action)),
                                         ("Sheet", #selector(button3Action)),
                                         ("单队列", #selector(button4Action)),
                                         ("双队列", #selector(button5Action)),
                                         ("单队列叠加", #selector(button6Action)),
                                         ("VC", #selector(button7Action)),
                                         ("showImmediately", #selector(button8Action)),
                                         ("updateLayout", #selector(button9Action)),
                                         ("next", #selector(button10Action)),
                                         ("Single", #selector(button11Action))]
        
        for (idx, item) in buttonItems.enumerated() {
            let button = UIButton(type: .custom)
            button.frame = CGRectMake(100, 0, 100, 50)
            button.setTitle(item.title, for: .normal)
            button.backgroundColor = .red
            button.addTarget(self, action: item.sel, for: .touchUpInside)
            view.addSubview(button)
            
            button.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(150)
                make.height.equalTo(50)
                make.top.equalToSuperview().offset(100 + idx * 70)
            }
        }
    }

    
    @objc func button1Action() {
//        showCenter()
        
        let config = SMPopupConfig(sceneStyle: .center)
        config.dismissDuration = 4
        let pop = CenterPopView()
        SMPopupService.standard.show(config: config, view: pop)
        
        let config2 = SMPopupConfig(sceneStyle: .sheet)
        config2.dismissDuration = 2
        let pop2 = ButtomPopView()
        SMPopupService.coexistence.show(config: config2, view: pop2)
        
        let config3 = SMPopupConfig(sceneStyle: .push)
        config3.dismissDuration = 3
        let pop3 = TopBarPopView()
        customService.show(config: config3, view: pop3)
    }
    
    @objc func button2Action() {
        showTopbar()
    }
    
    @objc func button3Action() {
        showBottom()
    }
    
    @objc func button4Action() {
        showTopbar()
        showCenter()
        showBottom()
    }
    
    @objc func button5Action() {

//        showTestBottom(1, "1")
//        showTestCenter(2, "2")
//        showTestBottom(3, "3")
//        showTestCenter(4, "4")
//        showTestBottom(5, "5")
//        showTestCenter(6, "6")
//        showTestBottom(7, "7")
        
//        showTestBottom(0, "1")
//        showTestCenter(0, "2")
//        showTestBottom(0, "3")
//        showTestCenter(0, "4")
//        showTestBottom(0, "5")
//        showTestCenter(0, "6")
//        showTestBottom(0, "7")
        
        for i in 1...5 {
            show(scene: .push, priority: i, tag: "\(i)", queue: .default)
            show(scene: .center, priority: i, tag: "\(i)", queue: .coexistence)
        }
    }
    
    @objc func button6Action() {
        SMPopupService.standard.pause()
        for i in 1...5 {
            show(scene: .push, priority: i, tag: "\(i)", queue: .default)
        }
        SMPopupService.standard.continue()
    }
    
    @objc func button7Action() {
        showTestVC()
    }
    
    @objc func button8Action() {
        for i in 1...5 {
            show(scene: .push, priority: i, tag: "\(i)", queue: .default)
        }
        self.perform(#selector(showImmediately), with: nil, afterDelay: 3)
        self.perform(#selector(showImmediately), with: nil, afterDelay: 4)
        self.perform(#selector(showImmediately), with: nil, afterDelay: 5)
    }
    
    @objc func button9Action() {

        let config = SMPopupConfig(sceneStyle: .center)
        config.cornerRadius = 0
        config.showAnimationStyle = .bottomRise
        config.dismissAnimationStyle = .bottomFall
        config.identifier = "center"
        let pop = CenterPopView()
        pop.callbackBlock = { _ in
            SMPopupService.standard.dismiss()
        }
        SMPopupService.standard.show(config: config, view: pop)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            pop.updateLayout()
            UIView.animate(withDuration: 0.25) {
                pop.superview?.layoutIfNeeded()
            }
//            SMPopupService.standard.updateLayout(animate: true)
        }
    }
    
    @objc func button10Action() {
        navigationController?.pushViewController(NextViewController(), animated: true)
    }

    @objc func button11Action() {
        showBottom()
        
        let config = SMPopupConfig(sceneStyle: .center)
        config.cornerRadius = 0
        config.showAnimationStyle = .bottomRise
        config.dismissAnimationStyle = .bottomFall
        config.isClickCoverDismiss = true
        config.identifier = "center"
        let pop = CenterPopView()
        
        let popupProtocol =
        SMPopupService.standard.showSingle(config: config, view: pop) { popupView, config, event in
            print("\(event.eventScene) \(event.object)")
        }
        
        pop.callbackBlock = { [weak popupProtocol] _ in
            popupProtocol?.dismissSingle(true, completion: nil)
            popupProtocol?.sendEventSingle(SMPopupEvent.customEvent(scene: "Custom", object: "obj"))
        }
    }
}

extension ViewController {
    func showTestBottom(_ priority: Int = 0, _ tag: String? = nil, _ queue: SMPopupQueueType = .default) {
        let config = SMPopupConfig(sceneStyle: .sheet)
        config.cornerRadius = 18
        config.identifier = tag
        config.priority = priority
        config.rectCorners = [.topLeft, .topRight]
        let pop = ButtomPopView()
        pop.label.text = tag ?? "\(priority)"
        
        let service = queue == .default ? SMPopupService.standard : SMPopupService.coexistence
        service.show(config: config, view: pop)
    }
    func showTestCenter(_ priority: Int = 0, _ tag: String? = nil, _ queue: SMPopupQueueType = .default) {
        let config = SMPopupConfig(sceneStyle: .center)
        config.cornerRadius = 0
        config.showAnimationStyle = .topFall
        config.identifier = tag
        config.priority = priority
        let pop = CenterPopView()
        pop.label.text = tag ?? "\(priority)"
        pop.callbackBlock = { _ in
            SMPopupService.standard.dismiss()
        }
        
        let service = queue == .default ? SMPopupService.standard : SMPopupService.coexistence
        service.show(config: config, view: pop) { popupView, config, event in
            print("\(event.eventType), \(event.eventScene ?? ""), \(String(describing: event.object))")
        }
    }
    
    func showTestTop(_ priority: Int = 0, _ tag: String? = nil, _ queue: SMPopupQueueType = .default) {
        let config = SMPopupConfig(sceneStyle: .push)
        config.cornerRadius = 0
        config.identifier = tag
        config.priority = priority
        let pop = TopBarPopView()
        pop.label.text = tag ?? "\(priority)"
        
        let service = queue == .default ? SMPopupService.standard : SMPopupService.coexistence
        service.show(config: config, view: pop)
    }
    
    func show(scene: SMPopupScene, priority: Int = 0, tag: String? = nil, queue: SMPopupQueueType = .default) {
        let config = SMPopupConfig(sceneStyle: scene)
        config.identifier = tag
        config.priority = priority

        let service = queue == .default ? SMPopupService.standard : SMPopupService.coexistence

        let pop: (UIView & SMProtocol)
        switch scene {
        case .center:
            let p = CenterPopView()
            p.callbackBlock = { _ in
                service.dismiss()
            }
            pop = p
        case .sheet:
            pop = ButtomPopView()
        case .push:
            config.cornerRadius = 0
            pop = TopBarPopView()
        }
        
        pop.label.text = tag ?? "\(priority)"
        service.show(config: config, view: pop)
    }
}

extension ViewController {
    func showCenter(_ priority: Int = 0) {
        let config = SMPopupConfig(sceneStyle: .center)
        config.cornerRadius = 0
        config.showAnimationStyle = .bottomRise
        config.dismissAnimationStyle = .bottomFall
        config.identifier = "center"
        config.priority = priority
        let pop = CenterPopView()
        pop.callbackBlock = { _ in
            SMPopupService.standard.dismiss {
                print("complete")
            }
        }
        SMPopupService.standard.show(config: config, view: pop) { popupView, config, event in
            guard popupView == pop else { return }
            print("\(event.eventType), \(event.eventScene ?? ""), \(String(describing: event.object))")
        }
    }

    func showBottom(_ priority: Int = 0) {
        let config = SMPopupConfig(sceneStyle: .sheet)
        config.cornerRadius = 20
        config.identifier = "bottom"
        config.priority = priority
        let pop = ButtomPopView()
        SMPopupService.standard.show(config: config, view: pop)
    }
    
    func showTopbar(_ priority: Int = 0) {
        let config = SMPopupConfig(sceneStyle: .push)
        config.cornerRadius = 0
        config.dismissDuration = 3
        config.identifier = "top"
        config.priority = priority
        let pop = TopBarPopView()
        SMPopupService.standard.show(config: config, view: pop)
    }
    
    func showTopbar2(_ priority: Int = 0) {
        let config = SMPopupConfig(sceneStyle: .push)
        config.dismissDuration = 3
        config.priority = priority
        config.identifier = "top2"
        let pop = TopBarPopView()
        SMPopupService.standard.show(config: config, view: pop)
    }
    
    func showTestVC() {
        let config = SMPopupConfig(sceneStyle: .center)
        config.cornerRadius = 0
        config.showAnimationStyle = .bubble
        config.identifier = "center"
        
        let popVC = CenterVC()
        SMPopupService.standard.show(config: config, dataSource: popVC)
    }
    
    @objc func showImmediately() {
        let config = SMPopupConfig(sceneStyle: .center)
        config.cornerRadius = 0
        config.showAnimationStyle = .bubble
        config.identifier = "center"
        config.priority = 1
        config.level = .maxAndImmediately
        let pop = CenterPopView()
        SMPopupService.standard.show(config: config, view: pop)
    }
}

