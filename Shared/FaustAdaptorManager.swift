//
//  File.swift
//  File
//
//  Created by Ryan Allan on 8/19/21.
//

import Foundation

class FaustAdaptorManager: ObservableObject {
  weak var faustUnit: FaustAdaptorAudioUnit?
  
  init(_ faustUnit: FaustAdaptorAudioUnit? = nil) {
    self.faustUnit = faustUnit
    if let faustUnit = faustUnit {
      faustUnit.myManager = self
    }
  }
  
}
