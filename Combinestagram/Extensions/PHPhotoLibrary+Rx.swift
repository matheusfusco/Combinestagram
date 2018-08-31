//
//  PHPhotoLibrary+Rx.swift
//  Combinestagram
//
//  Created by Matheus on 31/08/18.
//  Copyright © 2018 Matheus. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import Photos

extension PHPhotoLibrary {
    static var authorized: Observable<Bool> {
        return Observable.create { observer in
            DispatchQueue.main.async {
                if authorizationStatus() == .authorized {
                    observer.onNext(true)
                    observer.onCompleted()
                }
                else {
                    observer.onNext(false)
                    
                    requestAuthorization { newStatus in
                        observer.onNext(newStatus == .authorized)
                        observer.onCompleted()
                    }
                }
            }
            return Disposables.create()
        }
    }
}
