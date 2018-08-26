import Foundation
import UIKit
import Photos
import RxSwift

class PhotoWriter {
    
    enum Errors: Error {
        case couldNotSavePhoto
    }
    
    static func save(_ image: UIImage) -> Single<String> {
        return Single.create(subscribe: { observer in
            var savedAssetID: String?
            
            PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                savedAssetID = request.placeholderForCreatedAsset?.localIdentifier
            }, completionHandler: { success, error in
                DispatchQueue.main.async {
                    if success, let id = savedAssetID {
                        observer(.success(id))
                    }
                    else {
                        observer(.error(error ?? Errors.couldNotSavePhoto))
                    }
                }
            })
            
            return Disposables.create()
        })
    }
}
