//
//  File.swift
//  File
//
//  Created by Ryan Allan on 8/19/21.
//

import Foundation
import Combine

class FaustAdaptorManager: ObservableObject {
  weak var faustUnit: FaustAdaptorAudioUnit?
  var changeStore = Set<AnyCancellable>()
  
  @Published var faustProgramString: String = "process = ef.reverseEchoN(1,128);"
  var faustRestoreString: String = "process = ef.reverseEchoN(1,128);"
  @Published var undoStates: [String] = []
  @Published var redoStates: [String] = []
  
  init(_ faustUnit: FaustAdaptorAudioUnit? = nil) {
    self.faustUnit = faustUnit
    if let faustUnit = faustUnit {
      faustUnit.myManager = self
    }
    self.objectWillChange.sink  { [weak self] _ in
      let undoString = self?.faustProgramString
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self, undoString]  in
        let newString = self?.faustProgramString
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [weak self, newString, undoString] in
          if let newString = newString, let undoString = undoString, let curr = self?.faustProgramString {
            if newString == curr && undoString != newString {
              if self?.undoStates.count ?? 0 > 50 {
                self?.undoStates.removeFirst()
              }
              self?.undoStates.append(undoString)
            }
          }
        }
      }
    }.store(in: &changeStore)
  }
  
  
  
}
