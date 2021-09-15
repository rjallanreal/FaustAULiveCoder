//
//  iOSViewController.swift
//  iOSViewController
//
//  Created by Ryan Allan on 8/19/21.
//

import UIKit
import FaustAULiveCoderFramework


class iOSViewController: UIViewController {

  override func viewDidLoad() {
      super.viewDidLoad()
      embedPlugInView()
  }
  
  func embedPlugInView() {
     let controller = loadViewController()
    // Present the view controller's view.
    if let view = controller.view {
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
      controller.didMove(toParent: self)
    }
  }
  
  
  private func loadViewController() -> UIViewController {
    // Locate the app extension's bundle in the main app's PlugIns directory
    guard let url = Bundle.main.builtInPlugInsURL?.appendingPathComponent("FaustAULiveCoderExtension.appex"),
      let appexBundle = Bundle(url: url) else {
          fatalError("Could not find app extension bundle URL.")
    }

    let storyboard = UIStoryboard(name: "iOSExtensionStoryboard", bundle: appexBundle)
    guard let controller = storyboard.instantiateInitialViewController() as? FaustLiveCoderAUViewController else {
        fatalError("Unable to instantiate FaustLiveCoderAUViewController")
    }
    return controller
  }
  
}
