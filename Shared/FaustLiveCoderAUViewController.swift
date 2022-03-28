//
//  FaustLiveCoderAUViewController.swift
//  FaustLiveCoderAUViewController
//
//  Created by Ryan Allan on 8/19/21.
//

import Foundation
import CoreAudioKit
import SwiftUI
import AVFoundation

public class FaustLiveCoderAUViewController: AUViewController {
  var testEngineManager = TestEngineManager()
  
  public var faustUnit: FaustAdaptorAudioUnit? {
    didSet {
      DispatchQueue.main.async {
        let faustHandle = FaustAdaptorManager(self.faustUnit)
        self.faustHandle = faustHandle
        let faustView = ContentView(faustHandle: faustHandle, testEngineManager: self.testEngineManager)
#if os(macOS)
        let controller = NSHostingController(rootView: faustView)
#else
        let controller = UIHostingController(rootView: faustView)
#endif
        self.addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(controller.view)
#if os(iOS)
        controller.didMove(toParent: self)
#endif
        NSLayoutConstraint.activate([
          controller.view.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 1.0),
          controller.view.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 1.0),
          controller.view.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
          controller.view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
        ])
      }
    }
  }
  
  var faustHandle: FaustAdaptorManager?
  
  /*public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
    if let faustUnit = faustUnit {
      return faustUnit
    }
    else {
      self.faustUnit = try! FaustAdaptorAudioUnit(componentDescription: componentDescription, options: [])
      return self.faustUnit!
    }
  }*/
  
  
  
  override public func viewDidLoad() {
    let bundleURL: URL = Bundle.main.bundleURL
    let bundlePathExtension: String = bundleURL.pathExtension
    let isAppex: Bool = bundlePathExtension ==  "appex"
    /*if faustUnit == nil {
      try! self.createAudioUnit(with: FaustLiveComponentDescription.componentDescription)
    }*/
    if !isAppex {
      print(FaustLiveComponentDescription.componentDescription.componentManufacturer)
      AUAudioUnit.registerSubclass(FaustAdaptorAudioUnit.self,
                                   as: FaustLiveComponentDescription.componentDescription,
                                   name: "Faust Adaptor Audio Unit",
                                   version: UInt32.max)
      print("BEFORE INSTNTIATE")
      AVAudioUnit.instantiate(with: FaustLiveComponentDescription.componentDescription) { audioUnit, error in
        guard error == nil, let audioUnit = audioUnit else {
            fatalError("Could not instantiate audio unit: \(String(describing: error))")
        }
        self.testEngineManager.testEngine = TestEngine(avAudioUnit: audioUnit, manager: self.testEngineManager)
        self.faustUnit = audioUnit.auAudioUnit as? FaustAdaptorAudioUnit
      }
    }
    
  }
  
  
}
