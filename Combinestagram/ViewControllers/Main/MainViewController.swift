import UIKit
import RxSwift

class MainViewController: UIViewController {
    
    // MARK: - IBOUtlets
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var buttonClear: UIButton!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var itemAdd: UIBarButtonItem!
    
    // MARK: - Lets and Vars
    private let bag = DisposeBag()
    private let images = Variable<[UIImage]>([])
    var imageCache = [Int]()
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let newImages = images.asObservable()
            .throttle(0.5, scheduler: MainScheduler.instance)
            .share(replay: 1)
        
        newImages
            .debounce(0.5, scheduler: MainScheduler.instance)
            .subscribe(
                onNext: { [weak self] photos in
                    guard let preview = self?.imagePreview else {
                        return
                    }
                    preview.image = UIImage.collage(images: photos,
                                                    size: preview.frame.size)
            })
            .disposed(by: bag)
        
        
        newImages
            .subscribe(onNext: { [weak self] photos in
                self?.updateUI(photos: photos)
            })
            .disposed(by: bag)
    }
    
    // MARK: - IBActions
    @IBAction func actionClear() {
        images.value = []
        imageCache = []
    }
    
    @IBAction func actionSave() {
        guard let image = imagePreview.image else { return }
        PhotoWriter.save(image)
            .subscribe(
                onSuccess: { [weak self] id in
                    self?.showMessage("Saved with id: \(id)")
                    self?.actionClear()
                },
                onError: { [weak self] error in
                    self?.showMessage("Error", description: error.localizedDescription)
            })
            .disposed(by: bag)
    }
    
    @IBAction func actionAdd() {
        //    images.value.append(UIImage(named: "Barcelona.jpg")!)
        guard let storyboard = storyboard else { return }
        let photosViewController = storyboard.instantiateViewController(withIdentifier: "PhotosViewController") as! PhotosViewController
        
        let newPhotos = photosViewController.selectedPhotos.share()
        
        newPhotos
            .takeWhile { [weak self] image in
                (self?.images.value.count ?? 0) < 6
            }
            .filter { newImage in
                newImage.size.width > newImage.size.height
            }
            .filter { [weak self] newImage in
                let len = newImage.pngData()?.count ?? 0
                guard self?.imageCache.contains(len) == false else {
                    return false
                }
                self?.imageCache.append(len)
                return true
            }
            .subscribe(
                onNext: { [weak self] newImage in
                    guard let images = self?.images else { return }
                    images.value.append(newImage)
                },
                onDisposed: {
                    print("finished photo selection")
            })
            .disposed(by: bag)
        
        
        newPhotos
            .ignoreElements()
            .subscribe(onCompleted: { [weak self] in
                self?.updateNavigationIcon()
            })
            .disposed(by: bag)
        
        guard let navigationController = navigationController else { return }
        navigationController.pushViewController(photosViewController, animated: true)
    }
    
    // MARK: - Custom Methods
    func updateNavigationIcon() {
        let icon = imagePreview.image?
        .scaled(CGSize(width: 22, height: 22))
        .withRenderingMode(.alwaysOriginal)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon, style: .done, target: nil, action: nil)
    }
    
    func showMessage(_ title: String, description: String? = nil) {
        alert(title: title, text: description)
            .subscribe()
            .disposed(by: bag)
    }
    
    private func updateUI(photos: [UIImage]) {
        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        buttonClear.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        self.title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }
}
