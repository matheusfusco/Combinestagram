import UIKit
import RxSwift

class MainViewController: UIViewController {
    
    
    @IBOutlet weak var imagePreview: UIImageView!
    @IBOutlet weak var buttonClear: UIButton!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var itemAdd: UIBarButtonItem!
    
    let bag = DisposeBag()
    let images = Variable<[UIImage]>([])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        images.asObservable()
            .subscribe(
                onNext: { [weak self] photos in
                    guard let preview = self?.imagePreview else {
                        return
                    }
                    preview.image = UIImage.collage(images: photos, size: preview.frame.size)
            })
            .disposed(by: bag)
        
        
        images.asObservable()
            .subscribe(onNext: { [weak self] photos in
                self?.updateUI(photos: photos)
            })
    }
    
    @IBAction func actionClear() {
        images.value = []
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
        
        photosViewController.selectedPhotos
            .subscribe(
                onNext: { [weak self] newImage in
                    guard let images = self?.images else { return }
                    images.value.append(newImage)
                },
                onDisposed: {
                    print("finished photo selection")
            })
            .disposed(by: bag)
        
        guard let navigationController = navigationController else { return }
        navigationController.pushViewController(photosViewController, animated: true)
    }
    
    func showMessage(_ title: String, description: String? = nil) {
        let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { [weak self] _ in self?.dismiss(animated: true, completion: nil)}))
        present(alert, animated: true, completion: nil)
    }
    
    func updateUI(photos: [UIImage]) {
        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        buttonClear.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        self.title = photos.count > 0 ? "\(photos.count)/6 photos" : "Combinestagram"
    }
}
