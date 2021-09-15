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
}
