//
//  ButtomPopView.swift
//  PopupTest
//
//  Created by 董德富 on 2023/9/4.
//

import Foundation
import UIKit

class ButtomPopView: UIView, SMProtocol {
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func customPopupView() -> UIView {
        return self
    }
    
    func layout(superView: UIView) {
        self.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(220)
        }
    }
    
//    func popupDidAppear() {
//        print(#function)
//    }
//
//    func popupDidDisappear() {
//        print(#function)
//    }
//    
//    func popupWillAppear() {
//        print(#function)
//    }
//    
//    func popupWillDisappear() {
//        print(#function)
//    }
    
    deinit {
        print("\(type(of: self)) -> \(#function)")
    }
    
    let imageView = UIImageView(image: UIImage(named: "bottomShare"))
    
    let label = UILabel()
}
