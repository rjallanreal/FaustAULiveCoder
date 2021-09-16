//
//  KeyboardHeightPublisher.swift
//  KeyboardHeightPublisher
//
//  Created by Ryan Allan on 9/16/21.
//
import UIKit
import Combine

extension Publishers {
  static var keyboardHeight: AnyPublisher<CGFloat, Never> {
    let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification).map
    { x  -> CGFloat in
      
      guard let keyboardFrame = x.userInfo?[UIResponder.keyboardFrameEndUserInfoKey/*UIKeyboardFrameEndUserInfoKey*/] as? NSValue else { return CGFloat(0) }
      return keyboardFrame.cgRectValue.height
      
    }
    
      
    
    let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
      .map { _ in CGFloat(0) }
    
    return MergeMany(willShow, willHide)
      .eraseToAnyPublisher()
  }
}

