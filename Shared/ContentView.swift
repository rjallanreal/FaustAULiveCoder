//
//  ContentView.swift
//  Shared
//
//  Created by Ryan Allan on 8/11/21.
//

import SwiftUI
import Combine

struct ContentView: View {
  @ObservedObject var faustHandle: FaustAdaptorManager
  @ObservedObject var testEngineManager: TestEngineManager
  //@State private var testText: String = "hello"
  @State private var keyboardShown: Bool = false
  //@State private var keyboardHeight: CGFloat = 0
  @State private var errorHeight: CGFloat = 0
  @State private var textEditID: String = UUID().uuidString
  
  static let headerColor = Color(red: 56/255, green: 77/255, blue: 101/255)
  static let headerColorTwo = Color(red: 29/255, green: 156/255, blue: 229/255)
  
  static let compileColor = Color(red: 213/255, green: 229/255, blue: 247/255)
  
  static let errorColor = Color(red: 245/255, green: 219/255, blue: 230/255)
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        VStack (spacing: 0) {
          Rectangle()
            .fill(Self.headerColor)
            .frame(height: geometry.safeAreaInsets.top)
            .padding(.bottom, -geometry.safeAreaInsets.top)
            .ignoresSafeArea()
          ZStack {
            Rectangle()
              .fill(Self.headerColor)
              .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: 40)
            /*HStack {
              if !faustHandle.undoStates.isEmpty {
                Button(action: {
                  faustHandle.undo()
                }) {
                  Image(systemName:"arrow.uturn.backward.circle")
                      .resizable()
                      .frame(width: 30, height: 30)
                      .foregroundColor(Color.white)
                }
                .padding(.leading, 10)
              }
              
              Spacer()
            }*/
            Text("Pilgrim Faust")
              .foregroundColor(Color.white)
          }
          .ignoresSafeArea(.container, edges: .horizontal)
          
          Divider()
          if keyboardShown {
            ZStack {
              Rectangle()
                .fill(Self.compileColor)
                .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: 40)
              Button("COMPILE")  {
                self.faustHandle.compileProgram()
                textEditID = UUID().uuidString
              }
            }
          }
          ZStack {
            Rectangle()
              .fill(Self.compileColor)
              .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: 35)
              .ignoresSafeArea(.container, edges: .horizontal)
            HStack() {
              Text("import(\"stdfaust.lib\");")
                .foregroundColor(Self.headerColor)
                .padding(.leading, 5)
                .padding(.top, 5)
                .padding(.bottom, 5)
              Spacer()
            }
          }
          .ignoresSafeArea(.container, edges: .horizontal)
          
          TextEditor(text: $faustHandle.faustProgramString)
            .foregroundColor(Color.gray)
            .disableAutocorrection(true)
            .id(textEditID)

        }
        if !keyboardShown && testEngineManager.testEngine != nil && !faustHandle.showError {
          Button(action: {
            if testEngineManager.isPlaying {
              testEngineManager.stop()
            }
            else {
              testEngineManager.play()
            }
          }) {
            if testEngineManager.isPlaying {
              Image(systemName:"stop.circle")
                .resizable()
                .frame(width: 75, height: 75)
                .foregroundColor(Self.headerColor)
            }
            else {
              Image(systemName:"play.circle")
                .resizable()
                .frame(width: 75, height: 75)
                .foregroundColor(Self.headerColor)
            }
          }
          .ignoresSafeArea()
          .offset(x: (geometry.size.width / 2) - 75, y: (geometry.size.height / 2)  - 50)
        }
        if faustHandle.showError && !keyboardShown {
          ZStack {
            Text(faustHandle.errorString)
              .padding(.horizontal, 5)
              .padding(.top, 10)
              .padding(.bottom, 10 + geometry.safeAreaInsets.bottom)
              .background(
                Rectangle()
                  .fill(Self.errorColor)
                  .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing)
                  .ignoresSafeArea(.container, edges: .horizontal)
                  .overlay(
                    GeometryReader { proxy -> Path in
                      DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.05) {
                        self.errorHeight = proxy.size.height
                      }
                      return Path()
                    }
                  )
              )
              .ignoresSafeArea(.container, edges: .horizontal)
          }
          .offset(x: 0, y: (geometry.size.height/2 + geometry.safeAreaInsets.bottom - (self.errorHeight / 2)))
        }
        
      }
    }
    .onReceive(Publishers.keyboardShow) {
      self.keyboardShown = $0
    }/*
    .onReceive(Publishers.keyboardHeight) {
      self.keyboardHeight = $0
    }*/
  }
}

struct ContentView_Previews: PreviewProvider {
  static let faustHandle = FaustAdaptorManager()
  static let testEngineManager = TestEngineManager()
  
  static var previews: some View {
    ContentView(faustHandle: faustHandle, testEngineManager: testEngineManager)
  }
}
