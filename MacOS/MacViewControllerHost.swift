//
//  MacViewControllerHost.swift
//  MacViewControllerHost
//
//  Created by Ryan Allan on 8/15/21.
//

import Foundation
import SwiftUI
import CoreAudioKit
import FaustAULiveCoderFramework

class MacViewControllerHost: AUViewController, NSHostingController {
  @objc required dynamic init?(coder: NSCoder) {
    super.init(coder: coder, rootView: ContentView())
  }
}
