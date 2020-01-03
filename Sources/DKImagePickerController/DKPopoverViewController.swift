//
//  DKPopoverViewController.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 15/6/27.
//  Copyright (c) 2015年 ZhangAo. All rights reserved.
//

import UIKit

import SnapKit

fileprivate extension UIView {
    func convertOriginToWindow() -> CGPoint {
        return self.convert(CGPoint.zero, to: self.window)
    }
}

public func ArrowDefaultColor() -> UIColor {
    if #available(iOS 13, *) {
        return UIColor.systemGray6
    } else {
        return UIColor.white
    }
}

open class DKPopoverViewController: UIViewController {
    
    static weak var pvc: DKPopoverViewController?
    
    @objc open class func popoverViewController(_ viewController: UIViewController,
                                                fromView: UIView,
                                                detailVC: UIViewController) {
        let popoverViewController = DKPopoverViewController()
        
        popoverViewController.contentViewController = viewController
        popoverViewController.fromView = fromView
        
        popoverViewController.showInView(detailVC.view)
        popoverViewController.detailVC = detailVC as? DKAssetGroupDetailVC
        detailVC.addChild(popoverViewController)
        
        pvc = popoverViewController
    }
    
    @objc open class func dismissPopoverViewController() {
        pvc?.dismiss {
            pvc = nil
        }
    }
    
    private class DKPopoverView: UIView {
        
        var contentView: UIView! {
            didSet {
                self.contentView.clipsToBounds = true
                self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                self.addSubview(self.contentView)
            }
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()

            self.contentView.frame = CGRect(x: 0, y: 0, width: self.bounds.width,
                                            height: self.bounds.height)
        }
    }
        
    private var contentViewController: UIViewController!
    private var fromView: UIView!
    private var popoverView: DKPopoverView!
    
    weak var detailVC: DKAssetGroupDetailVC?
    
    // MARK: - Observers
    
    private var preferredContentSizeObserver: NSKeyValueObservation?
    
    override open func loadView() {
        super.loadView()
        
        let backgroundView = UIControl(frame: self.view.frame)
        backgroundView.backgroundColor = UIColor(white: 0.4, alpha: 0.4)
        backgroundView.addTarget(self, action: #selector(dismiss as () -> Void), for: .touchUpInside)
        backgroundView.autoresizingMask = self.view.autoresizingMask
        self.view = backgroundView
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        self.popoverView = DKPopoverView()
        self.view.addSubview(popoverView)
    }
    
    func showInView(_ view: UIView) {
        view.addSubview(self.view)
        
        self.popoverView.contentView = self.contentViewController.view
        self.popoverView.frame = self.calculatePopoverViewFrame()
        
        let fromViewInWindow = self.fromView.convertOriginToWindow()
        
        self.preferredContentSizeObserver = self.contentViewController.observe(\.preferredContentSize, options: .new, changeHandler: { [weak self] (vc, changes) in
            if changes.newValue != nil {
                self?.animatePopoverViewAfterChange()
            }
        })
        
        self.popoverView.transform = self.popoverView.transform.translatedBy(x: 0, y: -(self.popoverView.bounds.height / 2)).scaledBy(x: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.6, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 1.3, options: .allowUserInteraction, animations: {
            self.popoverView.transform = CGAffineTransform.identity
        }, completion: nil)
    }
    
    @objc func dismiss() {
        detailVC?.updateTitleView(false)
        dismiss {
            //
        }
    }
    
    func dismiss(completion: () -> Void) {
        self.preferredContentSizeObserver?.invalidate()
        
        UIView.animate(withDuration: 0.2, animations: {
            self.popoverView.transform = self.popoverView.transform.translatedBy(x: 0, y: -(self.popoverView.bounds.height / 2)).scaledBy(x: 0.01, y: 0.01)
        }, completion: { result in
            self.view.removeFromSuperview()
            self.removeFromParent()
        })
    }
    
    func calculatePopoverViewFrame() -> CGRect {
        let popoverY = self.fromView.convertOriginToWindow().y + self.fromView.bounds.height
        
        let preferredContentSize = self.contentViewController.preferredContentSize
        var popoverWidth = preferredContentSize.width
        if popoverWidth == UIView.noIntrinsicMetric {
            if UI_USER_INTERFACE_IDIOM() == .pad {
                popoverWidth = self.view.bounds.width * 0.6
            } else {
                popoverWidth = self.view.bounds.width
            }
        }
        
        let popoverHeight = min(preferredContentSize.height, view.bounds.height - popoverY - 40)
        
        return CGRect(
            x: 0,
            y: UIApplication.shared.statusBarFrame.height + 44,
            width: popoverWidth,
            height: popoverHeight
        )
    }
    
    // MARK: - Animation
    
    private func animatePopoverViewAfterChange() {
        UIView.animate(withDuration: 0.2, animations: {
            self.popoverView.frame = self.calculatePopoverViewFrame()
        })
    }
    
}
