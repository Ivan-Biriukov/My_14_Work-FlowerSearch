import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    private let pickerView = UIImagePickerController()
    private let wikipediaURL = "https://en.wikipedia.org/w/api.php"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickerView.delegate = self
        pickerView.allowsEditing = false
        imageView.layer.cornerRadius = 50
    }

    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            guard let ciImage = CIImage(image: userPickedImage) else {
                fatalError("Can not convert image to CIIImage")
            }
            detect(image: ciImage)
        }
        pickerView.dismiss(animated: true)
    }
    
    private func detect(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Can not convert model")
        }
        let request = VNCoreMLRequest(model: model) {(request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else {
                fatalError("Could not classify image.")
            }
            self.requestInfo(flowerName: classification.identifier)
            self.navigationItem.title = classification.identifier.capitalized
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        }
        catch {
            print(error)
        }
    }
    
    func requestInfo(flowerName: String) {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        AF.request(wikipediaURL, method: .get, parameters: parameters).responseJSON { (response) in
            switch response.result {
            case .success:
                let flowerJSON : JSON = JSON(response.value!)
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                self.textView.text = flowerDescription
            case .failure:
                print("did not get the wikipedia info")
            }
        }
    }
    
    
    @IBAction func cameraButton(_ sender: UIBarButtonItem) {
        pickerView.sourceType = .camera
        present(pickerView, animated: true)
    }
    
    @IBAction func galleryButton(_ sender: UIBarButtonItem) {
        pickerView.sourceType = .photoLibrary
        present(pickerView, animated: true)
    }
    
    
}

