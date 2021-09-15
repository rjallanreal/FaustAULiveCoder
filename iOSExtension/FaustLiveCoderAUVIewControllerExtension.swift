//
//  iOSAUViewController.swift
//  iOSAUViewController
//
//  Created by Ryan Allan on 8/15/21.
//

import Foundation
import CoreAudioKit
import FaustAULiveCoderFramework

extension FaustLiveCoderAUViewController: AUAudioUnitFactory {
  public func createAudioUnit(with componentDescription: AudioComponentDescription) throws -> AUAudioUnit {
    if let faustUnit = faustUnit {
      return faustUnit
    }
    else {
      self.faustUnit = try! FaustAdaptorAudioUnit(componentDescription: componentDescription, options: [])
      return self.faustUnit!
    }
  }
}

