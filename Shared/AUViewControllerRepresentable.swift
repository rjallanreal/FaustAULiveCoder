//
//  AUViewControllerRepresentable.swift
//  AUViewControllerRepresentable
//
//  Created by Ryan Allan on 8/11/21.
//

import Foundation
import CoreAudioKit
import SwiftUI

struct AUViewControllerRepresentable: UIViewControllerRepresentable {
  typealias UIViewControllerType = AUViewController
  func makeUIViewController(context: UIViewControllerRepresentableContext<AUViewControllerRepresentable>) -> AUViewController {
      let picker = AUViewController()
      return picker
  }

  func updateUIViewController(_ uiViewController: AUViewController, context: UIViewControllerRepresentableContext<AUViewControllerRepresentable>) {

  }
}
