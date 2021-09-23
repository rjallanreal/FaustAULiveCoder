//
//  File.swift
//  File
//
//  Created by Ryan Allan on 8/19/21.
//

import Foundation
import Combine
import SwiftUI

class FaustAdaptorManager: ObservableObject {
  weak var faustUnit: FaustAdaptorAudioUnit?
  var changeStore = Set<AnyCancellable>()
  
  @Published var faustProgramString: String = "process = ef.reverseEchoN(1,128);"
  var faustRestoreString: String = "process = ef.reverseEchoN(1,128);"
  
  @Published var undoStates: [String] = []
  @Published var redoStates: [String] = []
  
  @Published var errorString: String = ""
  @Published var showError = false
  
  private var willUndo: Bool = false
  private var undoCandidate: String?
  
  init(_ faustUnit: FaustAdaptorAudioUnit? = nil) {
    self.faustUnit = faustUnit
    if let faustUnit = faustUnit {
      faustUnit.myManager = self
    }
    /*self.objectWillChange.sink  { [weak self] _ in
      if self?.willUndo ?? false {
        return
      }
      if self?.undoCandidate == nil {
        self?.undoCandidate = self?.faustProgramString
      }
      
      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) { [weak self]  in
        self?.redoStates = []
        let newString = self?.faustProgramString
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [weak self, newString] in
          if let newString = newString, let undoString = self?.undoCandidate, let curr = self?.faustProgramString {
            if newString == curr && undoString != newString {
              if self?.undoStates.count ?? 0 > 50 {
                self?.undoStates.removeFirst()
              }
              self?.undoStates.append(undoString)
              self?.undoCandidate = nil
            }
          }
        }
      }
    }.store(in: &changeStore)*/
  }
  
  func undo() {
    willUndo = true
    if !undoStates.isEmpty {
      redoStates.append(faustProgramString)
      faustProgramString = undoStates.popLast()!
    }
    willUndo = false
  }
  
  func compileProgram() {
    self.errorString = ""
    self.showError = false
    self.faustUnit?.compileProgram()
  }
  
}
