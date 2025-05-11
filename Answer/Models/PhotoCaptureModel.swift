//
//  PhotoCaptureModel.swift
//  Answer
//
//  Created by Vineet Rai on 10-May-25.
//

import Foundation
import UIKit

struct PhotoCaptureModel {
    var capturedImage: UIImage?
    var alertInfo: AlertInfo?
    
    struct AlertInfo {
        var title: String
        var message: String
    }
}