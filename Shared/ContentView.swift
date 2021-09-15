//
//  ContentView.swift
//  Shared
//
//  Created by Ryan Allan on 8/11/21.
//

import SwiftUI

struct ContentView: View {
  @ObservedObject var faustHandle: FaustAdaptorManager
  @ObservedObject var testEngineManager: TestEngineManager
  
  var body: some View {
    Text("Hello, world!")
        .padding()
  }
}

struct ContentView_Previews: PreviewProvider {
  static let faustHandle = FaustAdaptorManager()
  static let testEngineManager = TestEngineManager()
  
  static var previews: some View {
    ContentView(faustHandle: faustHandle, testEngineManager: testEngineManager)
  }
}
