//
//  MacViewControllerHost.swift
//  MacViewControllerHost
//
//  Created by Ryan Allan on 8/15/21.
//

import Foundation
import SwiftUI
import CoreAudioKit
import FaustAULiveCoderFrameworkMac

class macOSViewController: NSViewController {
  override func viewDidLoad() {
      super.viewDidLoad()
      embedPlugInView()
  }
  
  func embedPlugInView() {
     let controller = loadViewController()
    // Present the view controller's view.
    let view = controller.view
      addChild(controller)
      view.frame = self.view.bounds
      self.view.addSubview(view)
      
      view.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        view.topAnchor.constraint(equalTo: self.view.topAnchor),
        view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
        view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
      ])
    
  }
  
  
  private func loadViewController() -> NSViewController {
    // Locate the app extension's bundle in the main app's PlugIns directory
    guard let url = Bundle.main.builtInPlugInsURL?.appendingPathComponent("FaustAULiveCoderExtension (macOS).appex"),
      let appexBundle = Bundle(url: url) else {
          fatalError("Could not find app extension bundle URL.")
    }

    let storyboard = NSStoryboard(name: "macOSExtensionStoryboard", bundle: appexBundle)
    guard let controller = storyboard.instantiateInitialController() as? FaustLiveCoderAUViewController else {
        fatalError("Unable to instantiate FaustLiveCoderAUViewController")
    }
    return controller
  }
}
