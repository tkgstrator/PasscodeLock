//
//  SwiftUIView.swift
//  PasscodeLock
//
//  Created by Devonly on 3/23/21.
//  Copyright © 2021 Yanko Dimitrov. All rights reserved.
//

import SwiftUI

public struct PasscodeLockView: View, UIViewControllerRepresentable {
    
    public typealias LockState = PasscodeLockViewController.LockState
    @Environment(\.presentationMode) var present
    @Binding var isSucceed: Bool
    let type: LockState
    let configuration: PasscodeLockConfigurationType
    
    public init(isSucceed: Binding<Bool>, type: LockState, configuration: PasscodeLockConfigurationType) {
        self._isSucceed = isSucceed
        self.type = type
        self.configuration = configuration
    }
    
    public func makeUIViewController(context: Context) -> PasscodeLockViewController {
        let uiViewController = PasscodeLockViewController(state: type, configuration: configuration)
        uiViewController.successCallback = { lock in
            isSucceed = true
        }
        
        uiViewController.dismissCompletionCallback = {
            present.wrappedValue.dismiss()
        }
        return uiViewController
    }
    
    public func updateUIViewController(_ uiViewController: PasscodeLockViewController, context: Context) {
    }
}
