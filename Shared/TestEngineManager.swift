//
//  TestEngineManager.swift
//  TestEngineManager
//
//  Created by Ryan Allan on 9/1/21.
//

import Foundation

class TestEngineManager: ObservableObject {
  @Published var isPlaying = false
  var testEngine: TestEngine?
  
  func play() {
    guard let testEngine = testEngine else {
      return
    }
    testEngine.startPlaying()
  }
  
  func stop() {
    guard let testEngine = testEngine else {
      return
    }
    testEngine.stopPlaying()
  }
}
