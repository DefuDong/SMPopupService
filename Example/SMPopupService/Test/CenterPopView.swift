//
//  CenterPopView.swift
//  StarMaker
//
//  Created by 董德富 on 2023/7/20.
//  Copyright © 2023 uShow. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import SMPopupService

fileprivate let scale: CGFloat = 1

/// 任务中心, 新人任务完成弹框
@objcMembers
class CenterPopView: UIView, SMProtocol {

    var callbackBlock: ((_ jump: Bool) -> Void)?
        
    private lazy var headImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "task_rookie_head")
        return view
    }()
    
    private lazy var contentBorderView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderWidth = 6
        view.layer.borderColor = UIColor.orange.cgColor
        view.layer.cornerRadius = 18;
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .darkText
        label.textAlignment = .center
//        label.text = SM_LocalizedStringWithKey("task_login_rewards")
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.numberOfLines = 2
        label.textAlignment = .center
        return label
    }()
    
    private lazy var coinsContentView: CoinsContentView = CoinsContentView()
    
    private lazy var confirmButton: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 18
        button.layer.masksToBounds = true
        button.backgroundColor = .red
        button.titleLabel?.textColor = UIColor.white
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        button.addTarget(self, action: #selector(confirmButtonAction), for: .touchUpInside)
        button.setContentHuggingPriority(.required, for: .horizontal) //抗拉伸
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal) //不易被压缩
        return button
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        
        setupViews()
        
        let model = CenterPopView.testModel()
        titleLabel.text = model.name
        descLabel.text = model.describe
        coinsContentView.list = model.rewardList
        
        let buttonText = model.buttonText.isEmpty ? "Confirm" : model.buttonText
        let confirmText = "     " + buttonText + "     "
        confirmButton.setTitle(confirmText, for: .normal)
    }
    
    private func setupViews() {
        addSubview(contentBorderView)
        addSubview(headImageView)

        contentBorderView.addSubview(titleLabel)
        contentBorderView.addSubview(descLabel)
        contentBorderView.addSubview(coinsContentView)
        contentBorderView.addSubview(confirmButton)

        //head
        headImageView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.height.equalTo(headImageView.snp_width).multipliedBy(93 / 292 * scale)
        }
        
        //
        contentBorderView.snp.makeConstraints { make in
            make.top.equalTo(headImageView.snp_bottom).offset(-17 * scale)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(38 * scale)
            make.leading.trailing.equalToSuperview().inset(15)
            make.height.equalTo(25)
        }
        
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp_bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(15)
            make.height.greaterThanOrEqualTo(16)
        }
        
        coinsContentView.snp.makeConstraints { make in
            make.top.equalTo(descLabel.snp_bottom).offset(15)
            make.centerX.equalToSuperview()
        }
        
        confirmButton.snp.makeConstraints { make in
            make.top.equalTo(coinsContentView.snp_bottom).offset(15)
            make.height.equalTo(36)
            make.bottom.equalToSuperview().inset(24)
            make.centerX.equalToSuperview()
            make.width.greaterThanOrEqualTo(176 * scale)
            make.leading.trailing.greaterThanOrEqualToSuperview().inset(15).priorityMedium()
        }
        
        addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    @objc func confirmButtonAction() {
        SMPopupService.sendEvent(SMPopupEvent.customEvent(scene: "custom", object: "dismiss_callback"))
        callbackBlock?(true)
    }

    class CoinsContentView: UIView {
        let coin1: CoinView = CoinView()
        let coin2: CoinView = CoinView()
        
        
        var list: [SMTaskRookieReward]? {
            didSet {
                guard let list = list, !list.isEmpty else { return }
                coin1.isHidden = true
                coin2.isHidden = true
                coin1.snp.removeConstraints()
                coin2.snp.removeConstraints()

                if list.count == 1 {
                    coin1.model = list.first
                    coin1.isHidden = false
                    coin1.snp.remakeConstraints() { make in
                        make.width.equalTo(62)
                        make.edges.equalToSuperview()
                    }
                } else if list.count >= 2 {
                    coin1.model = list.first
                    coin1.isHidden = false
                    coin1.snp.remakeConstraints { make in
                        make.leading.top.bottom.equalToSuperview()
                        make.width.equalTo(62)
                    }
                    coin2.model = list[1]
                    coin2.isHidden = false
                    coin2.snp.makeConstraints { make in
                        make.trailing.top.bottom.equalToSuperview()
                        make.width.equalTo(62)
                        make.leading.equalTo(coin1.snp_trailing).offset(46)
                    }
                }
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(coin1)
            addSubview(coin2)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        class CoinView: UIView {
            var model: SMTaskRookieReward? {
                didSet {
                    titleLabel.text = model?.describe ?? ""
                }
            }
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                                
                addSubview(imageView)
                addSubview(titleLabel)
                
                imageView.snp.makeConstraints { make in
                    make.width.height.equalTo(48)
                    make.top.equalToSuperview()
                    make.centerX.equalToSuperview()
                }
                titleLabel.snp.makeConstraints { make in
                    make.leading.trailing.bottom.equalToSuperview()
                    make.top.equalTo(imageView.snp_bottom).offset(4)
                }
            }
            
            required init?(coder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            private lazy var imageView: UIImageView = UIImageView(image: UIImage(named: "coin_gold"))
            
            private lazy var titleLabel: UILabel = {
                let label = UILabel()
                label.font = UIFont.systemFont(ofSize: 12)
                label.textColor = .black
                label.textAlignment = .center
                label.numberOfLines = 2
                return label
            }()
        }
    }
    
    let label = UILabel()

    static func testModel() -> SMTaskRookiePopup {
        let model = SMTaskRookiePopup()
        model.rewardList = [SMTaskRookieReward(), SMTaskRookieReward()]
        return model
    }
        
    func updateLayout() {
        self.snp.updateConstraints { make in
            make.centerY.equalToSuperview().offset(-100)
        }
    }

    func layout(superView: UIView) {
        self.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(292 * scale)
        }
    }
    
    func executeCustomShowAnimation(complete: @escaping (Bool) -> Void) {
        let animate = CAKeyframeAnimation.init(keyPath: "transform")
        animate.duration = 0.25
        animate.values = [NSValue.init(caTransform3D: CATransform3DMakeScale(1.5, 1.5, 1.0)),
                          NSValue.init(caTransform3D: CATransform3DIdentity)]
//        animate.timingFunctions = [CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeInEaseOut),
//                                   CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeInEaseOut)]
        layer.add(animate, forKey: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            complete(true)
        }
    }
    
    func executeCustomDismissAnimation(complete: @escaping (Bool) -> Void) {
        UIView.animate(withDuration: 0.25) {
            self.layer.position = CGPoint(x: 0, y: 0)
        } completion: { finish in
            complete(finish)
        }
        
//        let animate = CAKeyframeAnimation.init(keyPath: "transform")
//        animate.duration = 0.25
//        animate.values = [NSValue.init(caTransform3D: CATransform3DIdentity),
//                          NSValue.init(caTransform3D: CATransform3DMakeScale(0.2, 0.2, 1.0)),]
//        animate.timingFunctions = [CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeInEaseOut),
//                                   CAMediaTimingFunction.init(name: CAMediaTimingFunctionName.easeInEaseOut)]
//        layer.add(animate, forKey: nil)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
//            complete(true)
//        }
    }
    
    deinit {
        print("\(type(of: self)) -> \(#function)")
    }
}


class SMTaskRookiePopup: NSObject {
    var name: String = "AAAAAAAAAAA" // 任务昵称
    var describe: String = "bbbbbbbbbbbbbbbbbbbbbbb" //
    var buttonText: String = "Confirm" // 按钮文案
    var deepLink: String = "" // 跳转
    var rewardList: [SMTaskRookieReward]?
}

class SMTaskRookieReward: NSObject {
    var type: Int = 0
    var num: Int = 0
    var describe: String = "X100" // 奖励描述：可能是昵称
    var icon: String = ""
}
