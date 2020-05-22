//
//  NetworkLayer.swift
//  AAInfographics
//
//  Created by Genie Sun on 2020/5/22.
//

import Foundation

public struct NetworkLayer {
    public static var forceLogoutAction: (() -> Void)?
    public var didFinishWithSuccess: () -> Void
    public var didFinishWithError: () -> Void
    public var didExecuteWithError: (_ error: Error?) -> Void
}
