//
//  KeyboardReadable.swift
//  KeyboardReadable
//
//  Created by Ryan Allan on 9/15/21.
//
import SwiftUI
import Combine

extension Publishers {
  static var keyboardShow: AnyPublisher<Bool, Never> {
#if os(macOS)
    return Empty<Bool, Never>(completeImmediately: false).eraseToAnyPublisher()
#else
    let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification).map
    { _ in true }
    
      
    
    let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
      .map { _ in false}
    
    return MergeMany(willShow, willHide)
      .eraseToAnyPublisher()

#endif
}
}

