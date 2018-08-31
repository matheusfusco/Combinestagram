import UIKit
import Photos
import RxSwift

class PhotosViewController: UICollectionViewController {
    
    // MARK: - Lets and Vars
    // MARK: Public variables
    var selectedPhotos: Observable<UIImage> {
        return selectedPhotosSubject.asObservable()
    }
    // MARK: Private variables
    private let disposeBag = DisposeBag()
    private let selectedPhotosSubject = PublishSubject<UIImage>()
    private lazy var photos = PhotosViewController.loadPhotos()
    private lazy var imageManager = PHCachingImageManager()
    private lazy var thumbnailSize: CGSize = {
        let cellSize = (self.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
        return CGSize(width: cellSize.width * UIScreen.main.scale,
                      height: cellSize.height * UIScreen.main.scale)
    }()
    
    // MARK: - Custom Methods
    static func loadPhotos() -> PHFetchResult<PHAsset> {
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        return PHAsset.fetchAssets(with: allPhotosOptions)
    }
    
    func errorMessage() {
        alert(title: "No access to Camera Roll",
              text: "You can grant access to Combinestagram from the Settings app")
            .asObservable()
            .subscribe(onCompleted: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
                _ = self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let authorized = PHPhotoLibrary.authorized.share()
        
        authorized
            .skipWhile { $0 == false }
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                self?.photos = PhotosViewController.loadPhotos()
                
                DispatchQueue.main.async {
                    self?.collectionView?.reloadData()
                }
            })
            .disposed(by: disposeBag)
        
        authorized
            .takeLast(1)
            .filter { $0 == false }
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                DispatchQueue.main.async {
                    self.errorMessage()
                }
            })
            .disposed(by: disposeBag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        selectedPhotosSubject.onCompleted()
    }
    
    // MARK: - UICollectionView Methods
    // MARK: DataSource
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let asset = photos.object(at: indexPath.item)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PhotoCell
        
        cell.representedAssetIdentifier = asset.localIdentifier
        
        imageManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: nil, resultHandler: { image, _ in
            if cell.representedAssetIdentifier == asset.localIdentifier {
                cell.imageView.image = image
            }
        })
        
        return cell
    }
    
    // MARK: Delegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let asset = photos.object(at: indexPath.item)
        
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCell {
            cell.flash()
        }
        
        imageManager.requestImage(for: asset, targetSize: view.frame.size, contentMode: .aspectFill, options: nil, resultHandler: { [weak self] image, info in
            guard let image = image, let info = info else { return }
            
            if let isThumbnail = info[PHImageResultIsDegradedKey as NSString] as? Bool, !isThumbnail {
                self?.selectedPhotosSubject.onNext(image)
            }
        })
    }
}
