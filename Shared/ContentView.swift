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
  @State private var keyboardHeight: CGFloat = 0
  @State private var textEditID: String = UUID().uuidString
  
  static let headerColor = Color(red: 56/255, green: 77/255, blue: 101/255)
  static let headerColorTwo = Color(red: 29/255, green: 156/255, blue: 229/255)
  
  static let compileColor = Color(red: 213/255, green: 229/255, blue: 247/255)
  
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
            Text("Faust Live Coder")
              .foregroundColor(Color.white)
          }
          .ignoresSafeArea(.container, edges: .horizontal)
          
          Divider()
          
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
        if !keyboardShown && testEngineManager.testEngine != nil {
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
        if keyboardShown {
          ZStack {
            Rectangle()
              .fill(Self.compileColor)
              .frame(width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing, height: 40)
            Button("COMPILE")  {
              textEditID = UUID().uuidString
            }
          }
          .ignoresSafeArea()
          .offset(x: 0, y: (geometry.size.height/2 - 20))
        }
      }
    }
    .onReceive(Publishers.keyboardShow) {
      self.keyboardShown = $0
    }
    .onReceive(Publishers.keyboardHeight) {
      self.keyboardHeight = $0
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static let faustHandle = FaustAdaptorManager()
  static let testEngineManager = TestEngineManager()
  
  static var previews: some View {
    ContentView(faustHandle: faustHandle, testEngineManager: testEngineManager)
  }
}
