//
//  FaustAdaptorAudioUnit.swift
//  FaustAdaptorAudioUnit
//
//  Created by Ryan Allan on 8/15/21.
//

import Foundation
import CoreAudioKit
#if os(macOS)
import FaustAdapterMac
#else
import FaustAdapter
#endif
import AudioToolbox
import AVFAudio
import Dispatch
import Atomics

public class FaustAdaptorAudioUnit: AUAudioUnit {
  final class FaustItems {
    var myDSPFactory: OpaquePointer?
    var myDSP: OpaquePointer?
    var faustSemaphore = DispatchSemaphore(value: 1)
    var killSwitch = ManagedAtomic<Bool>(false)
  }
  final class BufferRenderParameters {
    var inputAudioBufferList: UnsafePointer<AudioBufferList>?
    var inputMutableAudioBufferList: UnsafeMutablePointer<AudioBufferList>?
    var maxFrames: AUAudioFrameCount = 512
  }
  private let faustItems = FaustItems()
  private let bufferRenderParameters = BufferRenderParameters()
  private var pcmBuffer: AVAudioPCMBuffer?
  private var audioFormat = AVAudioFormat.init(standardFormatWithSampleRate: 44100, channels: 2)!
  
  private let dspSwitchDispatch = DispatchQueue(label: "switchFaustDSPHere")
  
  private var initCounter =  0
  
  weak var myManager: FaustAdaptorManager?
  
  lazy private var inputBusArray: AUAudioUnitBusArray = {
    let busses = try! AUAudioUnitBus.init(format: audioFormat)
    busses.maximumChannelCount = 8
    let busArray = AUAudioUnitBusArray(audioUnit: self, busType: .input, busses: [busses]  )
    return busArray
  }()
  
  lazy private var outputBusArray: AUAudioUnitBusArray = {
    let busses = try! AUAudioUnitBus.init(format: audioFormat)
    let busArray = AUAudioUnitBusArray(audioUnit: self, busType: .output, busses: [busses]  )
    return busArray
  }()

  public override var inputBusses: AUAudioUnitBusArray {
      return inputBusArray
  }

  public override var outputBusses: AUAudioUnitBusArray {
      return outputBusArray
  }
  
  // May change this to allow user to save faust files to use 
  public override var supportsUserPresets: Bool {
      return false
  }
    
  public override var canProcessInPlace: Bool {
    return true
  }
  
  public override var maximumFramesToRender: AUAudioFrameCount {
    get {
      return bufferRenderParameters.maxFrames
    }
    set {
      if !renderResourcesAllocated {
        bufferRenderParameters.maxFrames = newValue
      }
    }
  }
  
  public override func allocateRenderResources() throws {
    if outputBusses[0].format.channelCount != inputBusses[0].format.channelCount {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioUnitErr_FailedInitialization), userInfo: nil)
    }
    try super.allocateRenderResources()
    
    let factoryName: NSString = "faustAdaptorFactory"
    let C_factoryName = UnsafePointer<CChar>(factoryName.utf8String)
    let faustProgram: String = "import(\"\(Bundle.main.url(forResource: "stdfaust", withExtension: "lib", subdirectory: "faustlibraries")!.absoluteString)\"); \(myManager?.faustProgramString ?? "process = _;")"
    let C_faustProgram = UnsafePointer<CChar>((faustProgram as NSString).utf8String)
    var errorMsg: UnsafeMutablePointer<CChar>? = UnsafeMutablePointer<CChar>(nil)
    
    let newDSPFactory = create_faust_factory_from_string(C_factoryName, C_faustProgram, 0, nil, &errorMsg) //Int32(CommandLine.argc), values)
    
    var errorString = String(cString: errorMsg!)
    
    if !errorString.isEmpty {
      errorString.removeFirst(21)
      errorString.remove(at: errorString.index(errorString.startIndex, offsetBy: 2))
      errorString.remove(at: errorString.index(errorString.startIndex, offsetBy: 3))
      errorString.insert("\n", at: errorString.index(errorString.startIndex, offsetBy: 3))
      errorString = "Faust compiler found issue with line" + errorString
      myManager?.errorString = errorString
      myManager?.showError = true
      defaultDSP()
    }
    else {
      let newDSP = create_faust_dsp(newDSPFactory)
      init_faust_dsp(newDSP, Int32(audioFormat.sampleRate))
      
      let numOfInputs = faust_dsp_inputs(newDSP)
      let numOfOutputs = faust_dsp_outputs(newDSP)
      
      if numOfInputs != 1 || numOfOutputs != 1 {
        print("inputs: \(numOfInputs), outputs: \(numOfOutputs)")
        myManager?.errorString = "Compiled faust was valid, but Pilgrim Faust requires the effect chain to have exactly one input and one output. The compiled faust has \(numOfInputs) inputs and \(numOfOutputs) outputs."
        myManager?.showError = true
        defaultDSP()
      }
      else {
        self.faustItems.myDSPFactory = newDSPFactory
        self.faustItems.myDSP = newDSP
      }
    }
    errorMsg?.deallocate()
    pcmBuffer = AVAudioPCMBuffer(pcmFormat: inputBusses[0].format, frameCapacity: bufferRenderParameters.maxFrames)!;
    bufferRenderParameters.inputAudioBufferList = pcmBuffer!.audioBufferList
    bufferRenderParameters.inputMutableAudioBufferList = pcmBuffer!.mutableAudioBufferList
  }
  
  private func defaultDSP() {
    let factoryName: NSString = "faustAdaptorFactory"
    let C_factoryName = UnsafePointer<CChar>(factoryName.utf8String)
    let faustProgram: String = "import(\"\(Bundle.main.url(forResource: "stdfaust", withExtension: "lib", subdirectory: "faustlibraries")!.absoluteString)\"); process = _;"
    let C_faustProgram = UnsafePointer<CChar>((faustProgram as NSString).utf8String)
    
    var errorMsg: UnsafeMutablePointer<CChar>? = UnsafeMutablePointer<CChar>(nil)
    
    let newDSPFactory = create_faust_factory_from_string(C_factoryName, C_faustProgram, 0, nil, &errorMsg) //Int32(CommandLine.argc), values)
    errorMsg?.deallocate()
    
    let newDSP = create_faust_dsp(newDSPFactory)
    init_faust_dsp(newDSP, Int32(audioFormat.sampleRate))
    self.faustItems.myDSPFactory = newDSPFactory
    self.faustItems.myDSP = newDSP
  }
  
  public override init(componentDescription: AudioComponentDescription,
                       options: AudioComponentInstantiationOptions = []) throws {



      // Create the super class.
      try super.init(componentDescription: componentDescription, options: options)

      // Log the component description values.
      log(componentDescription)
      
      // Set the default preset.
  }
  
  public override func deallocateRenderResources() {
    super.deallocateRenderResources()
    delete_faust_factory(faustItems.myDSPFactory)
    faustItems.myDSPFactory = nil
    faustItems.myDSP = nil
    pcmBuffer = nil
    initCounter = initCounter + 1
    print("NEW INITCOUNTER: \(initCounter)")
  }
  
  public override var internalRenderBlock: AUInternalRenderBlock {
    let bufferRenderParameters = self.bufferRenderParameters
    let faustItems = self.faustItems
    let initCounter = initCounter
    return { [bufferRenderParameters, faustItems, initCounter]
      actionFlags, timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead, pullInputBlock in
      if (frameCount > bufferRenderParameters.maxFrames) {
        return kAudioUnitErr_TooManyFramesToProcess;
      }
      var inputAudioBufferList = UnsafeMutablePointer(mutating: bufferRenderParameters.inputAudioBufferList!)
      var inputMutableAudioBufferList = bufferRenderParameters.inputMutableAudioBufferList!
      if (pullInputBlock == nil) {
          return kAudioUnitErr_NoConnection;
      }
      var pullFlags = AudioUnitRenderActionFlags(rawValue: 0)
      let byteSize = min(frameCount, bufferRenderParameters.maxFrames) * 4
      inputMutableAudioBufferList.pointee.mNumberBuffers = inputAudioBufferList.pointee.mNumberBuffers;
      
      var inputAudioBuffer = inputAudioBufferList.pointee.mBuffers
      var ownedBuffers = UnsafeBufferPointer<AudioBuffer>(start: &inputAudioBufferList.pointee.mBuffers, count: Int(inputAudioBufferList.pointee.mNumberBuffers))
      var mutableBuffers = UnsafeMutableBufferPointer<AudioBuffer>(start: &inputMutableAudioBufferList.pointee.mBuffers, count: Int(inputMutableAudioBufferList.pointee.mNumberBuffers))

      for i in 0 ..< Int(inputMutableAudioBufferList.pointee.mNumberBuffers) {
        mutableBuffers[i].mNumberChannels = ownedBuffers[i].mNumberChannels
        mutableBuffers[i].mData =  ownedBuffers[i].mData
        mutableBuffers[i].mDataByteSize = byteSize
      }
      var err = pullInputBlock!(&pullFlags, timestamp, frameCount, 0, inputMutableAudioBufferList)
      
      if err != 0 {
        return err
      }
      
      let outputBuffers = UnsafeMutableBufferPointer<AudioBuffer>(start: &outputData.pointee.mBuffers, count: Int(outputData.pointee.mNumberBuffers))
      
      if (outputBuffers[0].mData == nil) {
        for i in 0 ..< Int(outputData.pointee.mNumberBuffers) {
          outputBuffers[i].mData = mutableBuffers[i].mData
        }
      }
      if faustItems.killSwitch.load(ordering: .relaxed) {
        for i in 0 ..< Int(outputData.pointee.mNumberBuffers) {
          outputBuffers[i].mNumberChannels = mutableBuffers[i].mNumberChannels;
          outputBuffers[i].mDataByteSize = byteSize;
          var inputBuffer = UnsafeMutableRawBufferPointer(start: mutableBuffers[i].mData, count: Int(frameCount))
          var outputBuffer = UnsafeMutableRawBufferPointer(start: outputBuffers[i].mData, count: Int(frameCount))
          if inputBuffer.baseAddress != outputBuffer.baseAddress {
            for i in 0 ..< Int(frameCount) {
              outputBuffer[i] = inputBuffer[i]
            }
          }
        }
      }
      else {
        faustItems.faustSemaphore.wait()
        for i in 0 ..< Int(outputData.pointee.mNumberBuffers) {
          outputBuffers[i].mNumberChannels = mutableBuffers[i].mNumberChannels;
          outputBuffers[i].mDataByteSize = byteSize;
          var input: UnsafeMutablePointer<Float>? = mutableBuffers[i].mData!.bindMemory(to: Float.self, capacity: Int(frameCount))
          var output: UnsafeMutablePointer<Float>? = outputBuffers[i].mData!.bindMemory(to: Float.self, capacity: Int(frameCount))
          faust_compute(faustItems.myDSP, Int32(frameCount), &input, &output)
        }
        faustItems.faustSemaphore.signal()
      }
      return noErr
    }
  }

  func compileProgram() {
    self.dspSwitchDispatch.sync {
      let factoryName: NSString = "faustAdaptorFactory"
      let C_factoryName = UnsafePointer<CChar>(factoryName.utf8String)
      let faustProgram: String = "import(\"\(Bundle.main.url(forResource: "stdfaust", withExtension: "lib", subdirectory: "faustlibraries")!.absoluteString)\"); \(myManager?.faustProgramString ?? "process = _;")"
      let C_faustProgram = UnsafePointer<CChar>((faustProgram as NSString).utf8String)
      var errorMsg: UnsafeMutablePointer<CChar>? = UnsafeMutablePointer<CChar>(nil)
      
      let newDSPFactory = create_faust_factory_from_string(C_factoryName, C_faustProgram, 0, nil, &errorMsg) //Int32(CommandLine.argc), values)
      
      var errorString = String(cString: errorMsg!)
      
      if !errorString.isEmpty {
        if errorString.contains("faustAdaptorFactory") {
          errorString.removeFirst(21)
          errorString.remove(at: errorString.index(errorString.startIndex, offsetBy: 2))
          errorString.remove(at: errorString.index(errorString.startIndex, offsetBy: 3))
          errorString.insert("\n", at: errorString.index(errorString.startIndex, offsetBy: 3))
          errorString = "Faust compiler found issue with line" + errorString
        }
        else {
          errorString.removeFirst(12)
          errorString = "Faust compiler ran into an issue:\n" + errorString
        }
        myManager?.errorString = errorString
        myManager?.showError = true
      }
      else {
        let newDSP = create_faust_dsp(newDSPFactory)
        init_faust_dsp(newDSP, Int32(audioFormat.sampleRate))
      
        let numOfInputs = faust_dsp_inputs(newDSP)
        let numOfOutputs = faust_dsp_outputs(newDSP)
        
        if numOfInputs != 1 || numOfOutputs != 1 {
          myManager?.errorString = "Compiled faust was valid, but Pilgrim Faust requires the effect chain to have exactly one input and one output. The compiled faust has \(numOfInputs) inputs and \(numOfOutputs) outputs."
          myManager?.showError = true
        }
        else {
          
          self.faustItems.killSwitch.store(true, ordering: .relaxed)
          self.faustItems.faustSemaphore.wait()
          
          delete_faust_factory(self.faustItems.myDSPFactory)
          self.faustItems.myDSPFactory = newDSPFactory
          self.faustItems.myDSP = newDSP
          
          self.faustItems.faustSemaphore.signal()
          self.faustItems.killSwitch.store(false, ordering: .relaxed)
        }
      }
      errorMsg?.deallocate()
    }
  }
  
  public override func supportedViewConfigurations(_ availableViewConfigurations: [AUAudioUnitViewConfiguration]) -> IndexSet {
    var indexSet = IndexSet()

    /*let min = CGSize(width: 400, height: 100)
    let max = CGSize(width: 800, height: 500)*/

    for (index, config) in availableViewConfigurations.enumerated() {

      /*let size = CGSize(width: config.width, height: config.height)

      if size.width <= min.width && size.height <= min.height ||
          size.width >= max.width && size.height >= max.height ||
          size == .zero {

          indexSet.insert(index)
      }*/
      indexSet.insert(index)
    }
    return indexSet
  }
}

