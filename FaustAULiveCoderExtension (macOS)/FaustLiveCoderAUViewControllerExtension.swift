//
//  FaustLiveCoderAUViewControllerExtension.swift
//  FaustAULiveCoderExtension (macOS)
//
//  Created by Ryan Allan on 3/27/22.
//

import Foundation

import CoreAudioKit
import FaustAULiveCoderFrameworkMac

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
