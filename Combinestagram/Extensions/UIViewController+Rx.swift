//
//  UIViewController+Rx.swift
//  Combinestagram
//
//  Created by Matheus on 31/08/18.
//  Copyright © 2018 Matheus. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

extension UIViewController {
    func alert(title: String, text: String?) -> Completable {
        return Completable.create { [weak self] completable in
            let alertVC = UIAlertController(title: title, message: text, preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Close", style: .default, handler: { _ in
                completable(.completed)
            }))
            self?.present(alertVC, animated: true, completion: nil)
            return Disposables.create()
        }
    }
}
