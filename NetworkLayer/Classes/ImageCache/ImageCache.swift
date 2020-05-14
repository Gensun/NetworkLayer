//
//  ImageCache.swift
//  NetworkLayer
//
//  Created by Genie Sun on 2020/5/6.
//  Copyright © 2020 Lookingedu. All rights reserved.
//

import Foundation
import UIKit

public extension UIImageView {
    func setImage(from url: URL, with placheHolder: UIImage? = nil) {
        if placheHolder != nil { image = placheHolder }
        Downloader.sharedInstance.downloadImage(from: url) { (downloaded, _) in
            if let result = downloaded {self.image = result}
        }
    }
}
