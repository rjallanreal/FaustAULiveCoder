//
//  TestEngine.swift
//  TestEngine
//
//  Created by Ryan Allan on 9/1/21.
//

import AVFoundation

class TestEngine {
  private var myAVAudioUnit: AVAudioUnit
  private let stopPlayQueue = DispatchQueue(label: "com.pilgrim.testEngine.stopPlayQueue")
  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private var guitarScaleFile: AVAudioFile?
  private var isPlaying = false {
    didSet {
      DispatchQueue.main.async {
        guard let myManager = self.myManager else {return}
        myManager.isPlaying = self.isPlaying
      }
    }
  }
  weak var myManager: TestEngineManager?
  
  init(avAudioUnit: AVAudioUnit, manager: TestEngineManager) {
    myAVAudioUnit = avAudioUnit
    myManager = manager
    engine.attach(player)

    guard let fileURL = Bundle(for: type(of: self)).url(forResource: "guitarScaleFile", withExtension: "aif") else {
      fatalError("\"guitarScaleFile.aif\" file not found.")
    }
    do {
      let guitarScaleFile = try AVAudioFile(forReading: fileURL)
      self.guitarScaleFile = guitarScaleFile
      engine.connect(player, to: engine.mainMixerNode, format: guitarScaleFile.processingFormat)
    } catch {
      fatalError("Could not create AVAudioFile instance. error: \(error).")
    }

    engine.prepare()
    
    let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
    engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)
    
    engine.attach(avAudioUnit)

    engine.disconnectNodeInput(engine.mainMixerNode)

    if let format = guitarScaleFile?.processingFormat {
        engine.connect(player, to: avAudioUnit, format: format)
        engine.connect(avAudioUnit, to: engine.mainMixerNode, format: format)
    }
  }
  
  private func setiOSSessionActive(_ active: Bool) {
    #if os(iOS)
    do {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playback, mode: .default)
    try session.setActive(active)
    } catch {
      fatalError("Could not set Audio Session active \(active). error: \(error).")
    }
    #endif
  }
  
  private func startPlayingInternal() {
    setiOSSessionActive(true)
      
    loopGuitarScale()
    
    let hardwareFormat = engine.outputNode.outputFormat(forBus: 0)
    engine.connect(engine.mainMixerNode, to: engine.outputNode, format: hardwareFormat)
    
    do {
      try engine.start()
    } catch {
      isPlaying = false
      fatalError("Could not start engine. error: \(error).")
    }
    
    player.play()

    isPlaying = true
  }
  
  private func stopPlayingInternal() {
    player.stop()
    engine.stop()
    isPlaying = false
    setiOSSessionActive(false)
  }
  
  private func loopGuitarScale() {
    guard let guitarScaleFile = guitarScaleFile else {
        fatalError("`guitarScaleFile` must not be nil in \(#function).")
    }
      
    player.scheduleFile(guitarScaleFile, at: nil) {
      self.stopPlayQueue.async {
        if self.isPlaying {
          self.loopGuitarScale()
        }
      }
    }
  }
  
  public func startPlaying() {
    stopPlayQueue.sync {
      if !self.isPlaying { self.startPlayingInternal() }
    }
  }

  public func stopPlaying() {
    stopPlayQueue.sync {
      if self.isPlaying { self.stopPlayingInternal() }
    }
  }

  public func togglePlay() {
    if isPlaying {
        stopPlaying()
    } else {
        startPlaying()
    }
  }
}
