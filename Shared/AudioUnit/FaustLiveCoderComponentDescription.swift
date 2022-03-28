//
//  File.swift
//  File
//
//  Created by Ryan Allan on 8/19/21.
//

import Foundation
import AudioToolbox

public struct FaustLiveComponentDescription {
  public static var componentDescription: AudioComponentDescription = {

      // Ensure that AudioUnit type, subtype, and manufacturer match the extension's Info.plist values
      var componentDescription = AudioComponentDescription()
      componentDescription.componentType = kAudioUnitType_Effect
      componentDescription.componentSubType = 0x504c455a//0x4c636f64 //0x6c636f64 /*'lcod'*/
      componentDescription.componentManufacturer = 0x53755065 //0x506c676d /*'Plgm'*/
      componentDescription.componentFlags = 0
      componentDescription.componentFlagsMask = 0

      return componentDescription
  }()
}
