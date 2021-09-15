//
//  FaustAdaptorAudioUnit.swift
//  FaustAdaptorAudioUnit
//
//  Created by Ryan Allan on 8/15/21.
//

import Foundation
import CoreAudioKit
import FaustAdapter
import AudioToolbox
import AVFAudio

public class FaustAdaptorAudioUnit: AUAudioUnit {
  class FaustObjects {
    var myDSPFactory: OpaquePointer?
    var myDSPInterpreter: OpaquePointer?
  }
  private let faustObjects = FaustObjects()
  private var pcmBuffer: AVAudioPCMBuffer?
  private var audioFormat = AVAudioFormat.init(standardFormatWithSampleRate: 44100, channels: 2)!
  
  weak var myManager: FaustAdaptorManager?
  
  lazy private var inputBusArray: AUAudioUnitBusArray = {
    let busses = try! AUAudioUnitBus.init(format: audioFormat)
    let busArray = AUAudioUnitBusArray(audioUnit: self, busType: .input, busses: [busses]  )
    return busArray
  }()
  
  lazy private var outputBusArray: AUAudioUnitBusArray = {
    let busses = try! AUAudioUnitBus.init(format: audioFormat)
    let busArray = AUAudioUnitBusArray(audioUnit: self, busType: .input, busses: [busses]  )
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
  
  private var maxFrames: AUAudioFrameCount = 512
  
  public override var maximumFramesToRender: AUAudioFrameCount {
    get {
      return maxFrames
    }
    set {
      if !renderResourcesAllocated {
          maxFrames = newValue
      }
    }
  }
  
  public override func allocateRenderResources() throws {
   /*if kernelAdapter.outputBus.format.channelCount != kernelAdapter.inputBus.format.channelCount {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioUnitErr_FailedInitialization), userInfo: nil)
    }*/
    try super.allocateRenderResources()
    let values: UnsafeMutablePointer<UnsafePointer<Int8>?> =
            UnsafeMutableRawPointer(CommandLine.unsafeArgv).bindMemory(
                to: UnsafePointer<Int8>?.self,
                capacity: Int(CommandLine.argc)
            )
    
    let factoryName: NSString = "faustAdaptorFactory"
    let C_factoryName = UnsafePointer<CChar>(factoryName.utf8String)
    let faustProgram: NSString = "import(\"stdfaust.lib\"); process = ef.reverseEchoN(1,128);"
    let C_faustProgram = UnsafePointer<CChar>(faustProgram.utf8String)
    self.faustObjects.myDSPFactory = C_createInterpreterDSPFactoryFromString(C_factoryName, C_faustProgram, 0, nil) //Int32(CommandLine.argc), values)
    self.faustObjects.myDSPInterpreter = createDSPInstance_C_interpreter_dsp_factory(self.faustObjects.myDSPFactory)
    init_interpreter_dsp(self.faustObjects.myDSPInterpreter, Int32(audioFormat.sampleRate))
    pcmBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: maxFrames);
    //kernelAdapter.allocateRenderResources()
  }
  
  public override func deallocateRenderResources() {
    super.deallocateRenderResources()
    C_deleteInterpreterDSPFactory(faustObjects.myDSPFactory)
    faustObjects.myDSPFactory = nil
    faustObjects.myDSPInterpreter = nil
    pcmBuffer = nil
  }
  
  public override var internalRenderBlock: AUInternalRenderBlock {
    guard let pcmBuffer = pcmBuffer, self.faustObjects.myDSPInterpreter != nil else {
      return {actionFlags, timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead, pullInputBlock in
       return noErr
      }
    }
    let inputAudioBufferList = pcmBuffer.audioBufferList
    var inputMutableAudioBufferList = pcmBuffer.mutableAudioBufferList
    var faustObjects = self.faustObjects
    let maxFrames = self.maxFrames
    return { [inputAudioBufferList, inputMutableAudioBufferList, maxFrames, faustObjects]
      actionFlags, timestamp, frameCount, outputBusNumber, outputData, realtimeEventListHead, pullInputBlock in
      if (pullInputBlock == nil) {
          return kAudioUnitErr_NoConnection;
      }
      var pullFlags = AudioUnitRenderActionFlags(rawValue: 0)
      let byteSize = min(frameCount, maxFrames) * 4
      inputMutableAudioBufferList.pointee.mNumberBuffers = inputAudioBufferList.pointee.mNumberBuffers;
      
      var inputAudioBuffer = inputAudioBufferList.pointee.mBuffers
      
      let ownedBuffers = UnsafeBufferPointer<AudioBuffer>(start: &inputAudioBuffer, count: Int(inputAudioBufferList.pointee.mNumberBuffers))
      let mutableBuffers = UnsafeMutableBufferPointer<AudioBuffer>(start: &inputMutableAudioBufferList.pointee.mBuffers, count: Int(inputMutableAudioBufferList.pointee.mNumberBuffers))

      for i in 0 ..< Int(inputAudioBufferList.pointee.mNumberBuffers) {
        mutableBuffers[i].mNumberChannels = ownedBuffers[i].mNumberChannels;
        mutableBuffers[i].mData = ownedBuffers[i].mData;
        mutableBuffers[i].mDataByteSize = byteSize;
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
     
      for i in 0 ..< Int(outputData.pointee.mNumberBuffers) {
        var input: UnsafeMutablePointer<Float>? = mutableBuffers[i].mData!.bindMemory(to: Float.self, capacity: Int(frameCount))
        var output: UnsafeMutablePointer<Float>? = outputBuffers[i].mData!.bindMemory(to: Float.self, capacity: Int(frameCount))
        compute_interpreter_dsp(faustObjects.myDSPInterpreter, Int32(frameCount), &input, &output)
      }

      return noErr
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

