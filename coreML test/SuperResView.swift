//
//  SuperResView.swift
//  coreML test
//
//  Created by karan sharma on 16/10/24.
//
import SwiftUI
import CoreML
import Vision
import CoreImage


func applySuperResolution(to image: UIImage) -> UIImage? {
    guard let model = try? bsrgan(configuration: MLModelConfiguration()) else {
        print("Failed to load model")
        return nil
    }
    
    let targetSize = CGSize(width: 244, height: 244)
    
    // Convert UIImage to resize
    guard let resizedImage = resizeImage(image: image, targetSize: targetSize) else {
        print("Failed to create resized image")
        return nil
    }

    // Convert UIImage to CVPixelBuffer
    guard let pixelBuffer = resizedImage.toCVPixelBuffer() else {
        print("Failed to create pixel buffer")
        return nil
    }
    
    // Perform prediction
    guard let output = try? model.prediction(x: pixelBuffer) else {
        print("Failed to make prediction")
        return nil
    }
    
    // Convert output CVPixelBuffer back to UIImage
    return UIImage(pixelBuffer: output.activation_out)
}





func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
    let size = image.size

    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height

    // Calculate the new size
    var newSize: CGSize
    if widthRatio > heightRatio {
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
    }

    // Create a graphics context and draw the image
    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
    image.draw(in: CGRect(origin: .zero, size: newSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage
}
