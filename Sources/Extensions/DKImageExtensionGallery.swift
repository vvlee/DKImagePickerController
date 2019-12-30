//
//  DKImageExtensionGallery.swift
//  DKImagePickerController
//
//  Created by ZhangAo on 16/12/2017.
//  Copyright © 2017 ZhangAo. All rights reserved.
//

import Foundation
import DKPhotoGallery
import SnapKit

open class DKImageExtensionGallery: DKImageBaseExtension, DKPhotoGalleryDelegate {
    
    open weak var gallery: DKPhotoGalleryController?
    open var group: DKAssetGroup!
    
    override class func extensionType() -> DKImageExtensionType {
        return .gallery
    }
        
    override open func perform(with extraInfo: [AnyHashable: Any]) {
        guard let groupDetailVC = self.context.groupDetailVC
            , let groupId = extraInfo["groupId"] as? String else { return }
        
        guard let group = context.imagePickerController.groupDataManager.fetchGroup(with: groupId) else {
            assertionFailure("Expect group")
            return
        }
        
        if let gallery = self.createGallery(with: extraInfo, group: group) {
            self.gallery = gallery
            self.group = group
            
            if context.imagePickerController.inline {
                UIApplication.shared.keyWindow!.rootViewController!.present(photoGallery: gallery)
            } else {
                groupDetailVC.present(photoGallery: gallery)
            }
        }
    }
    
    open func createGallery(with extraInfo: [AnyHashable: Any], group: DKAssetGroup) -> DKPhotoGalleryController? {
        guard let groupDetailVC = self.context.groupDetailVC else { return nil }
        
        let presentationIndex = extraInfo["presentationIndex"] as? Int
        let presentingFromImageView = extraInfo["presentingFromImageView"] as? UIImageView
        
        var items: [DKPhotoGalleryItem] = []
        
        for i in 0..<group.totalCount {
            guard let phAsset = context.imagePickerController.groupDataManager.fetchPHAsset(group, index: i) else {
                assertionFailure("Expect phAsset")
                continue
            }
            
            let item = DKPhotoGalleryItem(asset: phAsset)
            
            if i == presentationIndex, let presentingFromImage = presentingFromImageView?.image {
                item.thumbnail = presentingFromImage
            }
            
            items.append(item)
        }
        
        let gallery = DKPhotoGalleryController()
        gallery.singleTapMode = .toggleControlView
        gallery.items = items
        gallery.galleryDelegate = self
        gallery.presentingFromImageView = presentingFromImageView
        gallery.presentationIndex = presentationIndex ?? 0
        gallery.finishedBlock = { dismissIndex, dismissItem in
            let cellIndex = groupDetailVC.adjustAssetIndex(dismissIndex)
            let cellIndexPath = IndexPath(row: cellIndex, section: 0)
            groupDetailVC.scroll(to: cellIndexPath)
            
            return groupDetailVC.thumbnailImageView(for: cellIndexPath)
        }
        
        return gallery
    }
    
    // MARK: - DKPhotoGalleryDelegate
    
    open lazy var backItem = UIBarButtonItem(image: DKImagePickerControllerResource.photoGalleryBackArrowImage(),
                                           style: .plain,
                                           target: self,
                                           action: #selector(dismissGallery))
    
    open func photoGallery(_ gallery: DKPhotoGallery, didShow index: Int) {
        if let viewController = gallery.topViewController {
            if viewController.navigationItem.rightBarButtonItem == nil {
                let button = UIButton(type: .custom)
                button.titleLabel?.font = UIFont(name: "Helvetica Neue", size: 13)
                button.addTarget(self, action: #selector(DKImageExtensionGallery.selectAssetFromGallery(button:)), for: .touchUpInside)
                button.setTitle("", for: .normal)
                
                button.setBackgroundImage(DKImagePickerControllerResource.photoGalleryCheckedImage(), for: .selected)
                button.setBackgroundImage(DKImagePickerControllerResource.photoGalleryUncheckedImage(), for: .normal)
                
                button.bounds = CGRect(x: 0, y: 0,
                                       width: DKImagePickerControllerResource.photoGalleryCheckedImage().size.width,
                                       height: DKImagePickerControllerResource.photoGalleryCheckedImage().size.height)
                
                let item = UIBarButtonItem(customView: button)
                viewController.navigationItem.rightBarButtonItem = item
            }
            
            viewController.navigationController?.navigationBar.tintColor = .black
            viewController.navigationController?.navigationBar.backgroundColor = .black
            
            viewController.navigationItem.leftBarButtonItem = nil
            
            // 禁用返回
//            if viewController.navigationItem.leftBarButtonItem != self.backItem {
//                viewController.navigationItem.leftBarButtonItem = self.backItem
//            }
            
            self.updateGalleryAssetSelection()
        }
    }
    
    @objc open func selectAssetFromGallery(button: UIButton) {
        if let gallery = self.gallery {
            let currentIndex = gallery.currentIndex()
            if let asset = self.context.imagePickerController.groupDataManager.fetchAsset(self.group,
                                                                                          index: currentIndex)
            {
                if button.isSelected {
                    self.context.imagePickerController.deselect(asset: asset)
                } else {
                    self.context.imagePickerController.select(asset: asset)
                }

                self.updateGalleryAssetSelection()
            }
        }
    }
    
    open func updateGalleryAssetSelection() {
        if let gallery = self.gallery, let button = gallery.topViewController?.navigationItem.rightBarButtonItem?.customView as? UIButton {
            let currentIndex = gallery.currentIndex()
            
            if let asset = self.context.imagePickerController.groupDataManager.fetchAsset(self.group,
                                                                                          index: currentIndex)
            {
//                var labelWidth: CGFloat = 0.0
                if let selectedIndex = self.context.imagePickerController.index(of: asset) {
                    gallery.updateHeaderView(true, index: selectedIndex)
//                    let title = "\(selectedIndex + 1)"
//                    button.setTitle(title, for: .selected)
//                    button.isSelected = true
//
//                    labelWidth = button.titleLabel!.sizeThatFits(CGSize(width: 100, height: 50)).width + 10
                } else {
//                    button.isSelected = false
//                    button.sizeToFit()
                    gallery.updateHeaderView(false)
                }

//                button.bounds = CGRect(x: 0, y: 0,
//                                       width: max(button.backgroundImage(for: .normal)!.size.width, labelWidth),
//                                       height: button.bounds.height)
            }
        }
    }
    
    @objc open func dismissGallery() {
        self.gallery?.dismissGallery()
    }

}

// MARK: - DKPhotoGalleryController

open class DKPhotoGalleryController: DKPhotoGallery {
    
    open override var prefersStatusBarHidden: Bool {
        return true
    }
    
    open var contentController: DKPhotoGalleryContentVC?
    
    fileprivate let galleryFooterView = DKGalleryFooterView()
    fileprivate let galleryHeaderView = DKGalleryHeaderView()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        isNavigationBarHidden = true
        
        contentController = viewControllers.first as? DKPhotoGalleryContentVC
        guard let v = contentController?.view else { return }
        
        galleryFooterView.gallery = self
        v.addSubview(galleryFooterView)
        galleryFooterView.snp.makeConstraints { (make) in
            make.leading.bottom.trailing.equalToSuperview()
            make.height.equalTo(100)
        }
        
        v.addSubview(galleryHeaderView)
        galleryHeaderView.selectBtn.addTarget(self, action: #selector(selectAction(_:)), for: .touchUpInside)
        galleryHeaderView.snp.makeConstraints { (make) in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(80)
        }
    }
    
    @objc func selectAction(_ btn: UIButton) {
        if let ext = galleryDelegate as? DKImageExtensionGallery {
            ext.selectAssetFromGallery(button: btn)
        }
    }
    
    fileprivate func updateHeaderView(_ isSelected: Bool, index: Int = -1) {
        let btn = galleryHeaderView.selectBtn
        if isSelected {
            btn.isSelected = true
            btn.setTitle("\(index + 1)", for: .selected)
            btn.layer.cornerRadius = 14
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.white.cgColor
            btn.setBackgroundImage(nil, for: .normal)
            btn.backgroundColor = UIColor(red: 1, green: 0.41, blue: 0.52, alpha: 1)
        } else {
            btn.isSelected = false
            btn.setTitle(nil, for: .normal)
            btn.layer.cornerRadius = 0
            btn.layer.borderWidth = 0
            btn.setBackgroundImage(DKImagePickerControllerResource.photoGalleryUncheckedImage(), for: .normal)
            btn.backgroundColor = .clear
        }
    }
    
    override open func updateNavigation() {
        // 禁用页码显示
    }
    
    var isShowContentView: Bool = true
    
    open override func toggleControlView() {
        isShowContentView ? hidesControlView() : showsControlView()
    }
    
    open override func showsControlView() {
        isShowContentView = true
    }
    
    open override func hidesControlView() {
        isShowContentView = false
    }
    
    open override func updateContextBackground(alpha: CGFloat, animated: Bool) {
        super.updateContextBackground(alpha: alpha, animated: animated)
        galleryFooterView.backBtn.alpha = alpha
        galleryFooterView.doneBtn.alpha = alpha
        galleryHeaderView.selectBtn.alpha = alpha
    }
}

// MARK: - DKGalleryFooterView

fileprivate class DKGalleryFooterView: UIView {
    
    weak var gallery: DKPhotoGalleryController?
    
    let backBtn = UIButton(type: .custom)
    let doneBtn = UIButton(type: .custom)
    
    convenience init() {
        self.init(frame: .zero)
        setup()
    }
    
    func setup() {
        let isIPhoneX: Bool = UIApplication.shared.statusBarFrame.height > 20
        let xOffset: CGFloat = isIPhoneX ? 20 : 0
        
        backBtn.setTitle("返回", for: .normal)
        backBtn.setTitleColor(.white, for: .normal)
        backBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        backBtn.titleLabel?.textAlignment = .center
        backBtn.addTarget(self, action: #selector(backAction(_:)), for: .touchUpInside)
        addSubview(backBtn)
        backBtn.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-25 - xOffset)
            make.leading.equalToSuperview().offset(70)
            make.size.equalTo(CGSize(width: 48, height: 32))
        }
        
        doneBtn.backgroundColor = UIColor(red: 1, green: 0.41, blue: 0.52, alpha: 1)
        doneBtn.clipsToBounds = true
        doneBtn.layer.cornerRadius = 20
        doneBtn.setTitle("确定", for: .normal)
        doneBtn.setTitleColor(.white, for: .normal)
        doneBtn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        doneBtn.titleLabel?.textAlignment = .center
        doneBtn.addTarget(self, action: #selector(doneAction(_:)), for: .touchUpInside)
        addSubview(doneBtn)
        doneBtn.snp.makeConstraints { (make) in
            make.centerY.equalTo(backBtn)
            make.trailing.equalToSuperview().offset(-55)
            make.size.equalTo(CGSize(width: 74, height: 40))
        }
        
    }
    
    @objc func backAction(_ btn: UIButton) {
        gallery?.dismissGallery()
    }
    
    @objc func doneAction(_ btn: UIButton) {
        gallery?.dismissGallery()
    }
}

// MARK: - DKGalleryHeaderView

fileprivate class DKGalleryHeaderView: UIView {
    
    let selectBtn: UIButton = UIButton(type: .custom)
    
    convenience init() {
        self.init(frame: .zero)
        setup()
    }
    
    func setup() {
        addSubview(selectBtn)
        selectBtn.setTitleColor(.white, for: .normal)
        selectBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        selectBtn.clipsToBounds = true
        selectBtn.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(13)
            make.trailing.equalToSuperview().offset(-28)
            make.size.equalTo(CGSize(width: 28, height: 28))
        }
    }
}
