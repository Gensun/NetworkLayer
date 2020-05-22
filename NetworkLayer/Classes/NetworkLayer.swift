//
//  NetworkLayer.swift
//  NetworkLayer
//
//  Created by Genie Sun on 2020/5/22.
//  Copyright © 2020 Lookingedu. All rights reserved.
//

import Foundation

public struct NetworkLayer {
    public static var forceLogoutAction: (() -> Void)?
    public static var didFinishWithSuccess: (() -> Void)?
    public static var didFinishWithError: ((_ error: Error?) -> Void)?
    public static var didExecuteWithError: ((_ error: Error?) -> Void)?
}
