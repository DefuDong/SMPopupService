//
//  TopBarPopView.swift
//  StarMaker
//
//  Created by 董德富 on 2023/7/20.
//  Copyright © 2023 uShow. All rights reserved.
//

import Foundation
import UIKit

/// 任务中心, 非新人任务弱弹框提示
@objcMembers
class TopBarPopView: UIView, SMProtocol {
    let SM_ScreenWidth = UIScreen.main.bounds.size.width
    let SM_StatusHeight = UIScreen.p_safeTop()

    override init(frame: CGRect) {
        super.init(frame: frame)
        //corner
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.masksToBounds = false
        //shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowOpacity = 1
        layer.shadowRadius = 4
        //subviews
        addSubview(icon)
        
        let container = UIView()
        container.backgroundColor = .clear
        addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(textLabel)
        
        let padding = 12
        icon.snp.makeConstraints { make in
            make.width.height.equalTo(40)
            make.leading.equalToSuperview().offset(padding)
            make.centerY.equalToSuperview()
        }
        container.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp_trailing).offset(8)
            make.trailing.equalToSuperview().inset(padding)
            make.centerY.equalToSuperview()
            make.top.bottom.greaterThanOrEqualToSuperview().inset(10)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
        }
        textLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp_bottom).offset(3)
            make.bottom.equalToSuperview()
        }
        
        addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "AAAAAAAAAAAAAAAAAAAAAAMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM"
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .left
        label.numberOfLines = 2;
        return label
    }()
    
    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.text = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbcccccccccccccccccccccccccccccccccccccccc"
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textAlignment = .left
        label.numberOfLines = 2;
        return label
    }()
    
    let label = UILabel()
    
    private lazy var icon: UIImageView = UIImageView(image: UIImage(named: "coin_gold"))
    
    func layout(superView: UIView) {
        self.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.top.equalToSuperview().offset(UIScreen.p_safeTop() + 8)
        }
    }
}
