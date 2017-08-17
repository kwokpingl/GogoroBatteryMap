//
//  IAPurchasable.swift
//  GogoroMap
//
//  Created by 陳 冠禎 on 2017/8/16.
//  Copyright © 2017年 陳 冠禎. All rights reserved.
//


// do verify recipts

import SwiftyStoreKit
import StoreKit
import Foundation
import UIKit


protocol PurchaseItem {}
extension String: PurchaseItem {}
extension RegisteredPurchase: PurchaseItem {}

protocol IAPPurchasable: IAPAlartable {
    
    func getInfo(_ purchase: RegisteredPurchase, completeHandle: @escaping ProductsRequestCompletionHandler)
    func purchase(_ result: SKProduct)
    func restore()
    func verifyPurchase<T: PurchaseItem>(_ purchase: T)
    
}



extension IAPPurchasable where Self: UIViewController {
    
    func getInfo(_ purchase: RegisteredPurchase, completeHandle: @escaping ProductsRequestCompletionHandler) {
        NetworkActivityIndicatorManager.networkOperationStarted()
        SwiftyStoreKit.retrieveProductsInfo([Bundle.id + "." + purchase.rawValue]) { result in
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            if let product = result.retrievedProducts.first {
                completeHandle(true, [product])
                return
            }
            self.showAlert(self.alertForProductRetrievalInfo(result))
            completeHandle(false, nil)
        }
    }
    
    
    func purchase(_ result: SKProduct) {
        NetworkActivityIndicatorManager.networkOperationStarted()
        SwiftyStoreKit.purchaseProduct(result, quantity: 1, atomically: true) { result in
            if case .success(let purchase) = result {
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                self.verifyPurchase(purchase.productId)
            }
            self.showAlert(self.alertForPurchase(result))
        }
    }
    
    
    
    func restore() {
        NetworkActivityIndicatorManager.networkOperationStarted()
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            
            for purchase in results.restoredPurchases where purchase.needsFinishTransaction {
                SwiftyStoreKit.finishTransaction(purchase.transaction)
            }
            
            if let productId = results.restoredPurchases.first?.productId {
                self.verifyPurchase(productId)
            }
        }
    }
    
    
    private func verifyReceipt(completion: @escaping (VerifyReceiptResult) -> Void) {
        
        let appleValidator = AppleReceiptValidator(service: .production)
        let password = Keys.standard.secretKet
        SwiftyStoreKit.verifyReceipt(using: appleValidator, password: password, completion: completion)
    }
    
    
    //    func verifyReceipt() {
    //
    //        NetworkActivityIndicatorManager.networkOperationStarted()
    //        verifyReceipt { result in
    //            NetworkActivityIndicatorManager.networkOperationFinished()
    //            self.showAlert(self.alertForVerifyReceipt(result))
    //        }
    //    }
    
    
    
    func verifyPurchase<T: PurchaseItem>(_ purchase: T) {
        
        NetworkActivityIndicatorManager.networkOperationStarted()
        print("verify Purchase")
        verifyReceipt { result in
            
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            switch result {
            case .success(let receipt):
                
                var productId: String
                if let purchase = purchase as? RegisteredPurchase {
                    productId = Bundle.id + "." + purchase.rawValue
                } else {
                    productId = purchase as! String
                }
                
                let purchaseResult = SwiftyStoreKit.verifyPurchase (
                    productId: productId,
                    inReceipt: receipt
                )
                
                switch purchaseResult {
                case .purchased(let item):
                    
                    self.deliverPurchaseNotificationFor(identifier: item.productId)
                    
                default:
                    print("no purchased item with:", productId)
                }
                
            case .error:
                break
            }
        }
    }
    
    
    fileprivate func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
        NetworkActivityIndicatorManager.networkOperationFinished()
        UserDefaults.standard.set(true, forKey: "hasPurchesd")
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: RegisteredPurchase.observerName, object: identifier)
    }
    
}




