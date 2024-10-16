//
//  ContentView.swift
//  coreML test
//
//  Created by karan sharma on 16/10/24.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    var body: some View {
        ImagePickerView()
    }
}

struct ImagePickerView: View {

    @State private var inputImage: UIImage?
    @State private var outputImage: UIImage?
    @State private var isPickerPresented = false // Controls picker
    @State private var isProcessing = false // For loading spinner
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            if let image = inputImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .foregroundColor(.gray)
            }

            if let output = outputImage {
                Image(uiImage: output)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                Text("Apply Super Resolution")
            }

            // Loading Spinner
            if isProcessing {
                ProgressView("Processing...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }

            // Error message display
            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }

            // Button to trigger image picker
            Button(action: {
                checkPhotoLibraryPermission()
            }) {
                Text("Select Image")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .sheet(isPresented: $isPickerPresented) {
                PhotoPicker(image: $inputImage) // Show the photo picker when the button is tapped
            }

            // Apply Super Resolution button
            Button(action: {
                if let inputImage = inputImage {
                    applySuperResolutionWithLoading(to: inputImage)
                } else {
                    errorMessage = "Please select an image first."
                }
            }) {
                Text("Apply Super Resolution")
                    .font(.title)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            // Optionally load an example image here
            inputImage = UIImage(named: "exampleImage")
        }
    }

    // Function to apply super resolution with loading and error handling
    func applySuperResolutionWithLoading(to image: UIImage) {
        isProcessing = true
        errorMessage = nil // Reset error message

        DispatchQueue.global(qos: .userInitiated).async {
            print("Applying super resolution to the image...")

            // Call the applySuperResolution function
            if let output = applySuperResolution(to: image) {
                DispatchQueue.main.async {
                    self.outputImage = output
                    self.isProcessing = false
                    print("Super resolution applied successfully.")
                }
            } else {
                DispatchQueue.main.async {
                    self.isProcessing = false
                    self.errorMessage = "Failed to apply super resolution."
                    print("Error: Failed to apply super resolution.")
                }
            }
        }
    }

    func checkPhotoLibraryPermission() {
            let status = PHPhotoLibrary.authorizationStatus()
            
            switch status {
            case .authorized:
                // Already authorized, present the picker
                isPickerPresented.toggle()
            case .denied, .restricted:
                // Access denied or restricted, maybe show an alert to the user
                print("Photo library access denied.")
            case .notDetermined:
                // Request access
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized {
                        // Access granted, present the picker
                        DispatchQueue.main.async {
                            isPickerPresented.toggle()
                        }
                    }
                }
            case .limited:
                // Limited access granted, present the picker
                isPickerPresented.toggle()
            @unknown default:
                print("Unknown authorization status.")
            }
        }
}

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images // Only show images
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { (image, error) in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
