//
//  TestViewController.swift
//  GogoroMap
//
//  Created by 陳 冠禎 on 2017/8/11.
//  Copyright © 2017年 陳 冠禎. All rights reserved.
//

import UIKit
import StoreKit

final class MenuController: UICollectionViewController, UICollectionViewDelegateFlowLayout, IAPPurchasable {
    
    let cellid = "cellid"
    let appID = Keys.standard.appID

    weak var mapViewController: MapViewController?
    
    var products = [SKProduct]() {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNaviagtionAndCollectionView()
        setupPurchaseItem()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellid, for: indexPath) as! StationsViewCell
        
        if let stationData = mapViewController?.stationData {
            cell.stationData = stationData
        }
        cell.menuController = self
        if !self.products.isEmpty {
            cell.product = self.products[indexPath.item]
        }
        cell.buyButtonHandler = { product in
            self.purchase(product)
        }
        
        return cell
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("selected \(indexPath.item)")
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: view.frame.width - 20 , height: view.frame.height - 90)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    
    func performGuidePage() {
        present(GuidePageViewController(), animated: true, completion: nil)
    }
    
    func recommand() {
        let head = "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id="
        let foot = "&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8"
        let url = head + appID + foot
        open(url: url)
    }
    
    func moreApp() {
        open(url: "https://itunes.apple.com/tw/app/id1192891004?l=zh&mt=8")
    }
    
    func shareThisApp() {
        guard let name = NSURL(string: "https://itunes.apple.com/tw/app/id\(appID)?l=zh&mt=8") else { return }
        let activityVC = UIActivityViewController(activityItems: [name], applicationActivities: nil)
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            activityVC.popoverPresentationController?.sourceView = self.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            activityVC.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
        }
        self.present(activityVC, animated: true, completion: nil)
    }
    
    func restorePurchase() {
        restore()
    }
    
    func presentMail() {
        presentErrorMailReport()
    }
    
    private func setupNaviagtionAndCollectionView() {
        navigationController?.view.layer.cornerRadius = 10
        navigationController?.view.layer.masksToBounds = true
        navigationController?.isNavigationBarHidden = false
        navigationItem.title = "更多資訊"
        navigationController?.view.backgroundColor = .clear
        navigationItem.titleView?.backgroundColor = .clear
        
        collectionView?.backgroundColor = .clear
        collectionView?.contentInset = UIEdgeInsetsMake(10, 10, 10, 10)
        collectionView?.isScrollEnabled = false
        collectionView?.showsVerticalScrollIndicator = false
        collectionView?.register(StationsViewCell.self, forCellWithReuseIdentifier: cellid)
    }
    
    private func open(url: String) {
        guard let checkURL = URL(string: url),
            UIApplication.shared.canOpenURL(checkURL) else { return }
        UIApplication.shared.openURL(checkURL)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: RegisteredPurchase.observerName, object: nil)
        print("menu controller deinitialize")
    }
    
    private func setupPurchaseItem() {
        guard let hasUserPurchased = mapViewController?.hasUserPurchased,
          !hasUserPurchased else { return }
        setupObserver()
        getInfo(.removeAds) { (success, products) in
            if success, let products = products {
                self.products = products
            }
        }
    }
}


// MARK: in-App purchase thing

extension MenuController {
    
    func handlePurchaseNotification(_ notification: Notification) {
        print("MenuController recieved notify")
        guard let productID = notification.object as? String,
            RegisteredPurchase.removedProductID == productID else { return }

            if let cell = collectionView?.visibleCells.first as? StationsViewCell {
                cell.buyStoreButtonStackView.removeFromSuperview()
                cell.layoutIfNeeded()
        }
    }
    
    fileprivate func setupObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handlePurchaseNotification(_:)),
                                               name: RegisteredPurchase.observerName,
                                               object: nil)
    }
    
}




