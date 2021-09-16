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
  final class FaustItems {
    var myDSPFactory: OpaquePointer?
    var myDSPInterpreter: OpaquePointer?
    var loopback = false
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
      print("GET MAXFRAMES: \(bufferRenderParameters.maxFrames)")
      return bufferRenderParameters.maxFrames
    }
    set {
      print("GET MAXFRAMES CHANGE: \(newValue)")
      if !renderResourcesAllocated {
        print("PUSHING IN CHANGE")
        bufferRenderParameters.maxFrames = newValue
      }
    }
  }
  
  public override func allocateRenderResources() throws {
    if outputBusses[0].format.channelCount != inputBusses[0].format.channelCount {
        throw NSError(domain: NSOSStatusErrorDomain, code: Int(kAudioUnitErr_FailedInitialization), userInfo: nil)
    }
    try super.allocateRenderResources()
    let values: UnsafeMutablePointer<UnsafePointer<Int8>?> =
            UnsafeMutableRawPointer(CommandLine.unsafeArgv).bindMemory(
                to: UnsafePointer<Int8>?.self,
                capacity: Int(CommandLine.argc)
            )
    
    let factoryName: NSString = "faustAdaptorFactory"
    let C_factoryName = UnsafePointer<CChar>(factoryName.utf8String)
    let faustProgram: String = "import(\"\(Bundle.main.url(forResource: "stdfaust", withExtension: "lib", subdirectory: "faustlibraries")!.absoluteString)\"); \(myManager?.faustProgramString ?? "process = ef.reverseEchoN(1,128);")"
    let C_faustProgram = UnsafePointer<CChar>((faustProgram as NSString).utf8String)
    self.faustItems.myDSPFactory = C_createInterpreterDSPFactoryFromString(C_factoryName, C_faustProgram, 0, nil) //Int32(CommandLine.argc), values)
    print("HERE WE GO")
    self.faustItems.myDSPInterpreter = createDSPInstance_C_interpreter_dsp_factory(self.faustItems.myDSPFactory)
    init_interpreter_dsp(self.faustItems.myDSPInterpreter, Int32(audioFormat.sampleRate))
    print("IN ALLOCATE, MAXFRAMEs \(bufferRenderParameters.maxFrames)")
    pcmBuffer = AVAudioPCMBuffer(pcmFormat: inputBusses[0].format, frameCapacity: bufferRenderParameters.maxFrames)!;
    bufferRenderParameters.inputAudioBufferList = pcmBuffer!.audioBufferList
    bufferRenderParameters.inputMutableAudioBufferList = pcmBuffer!.mutableAudioBufferList
    //kernelAdapter.allocateRenderResources()
  }
  
  public override func deallocateRenderResources() {
    super.deallocateRenderResources()
    C_deleteInterpreterDSPFactory(faustItems.myDSPFactory)
    faustItems.myDSPFactory = nil
    faustItems.myDSPInterpreter = nil
    pcmBuffer = nil
    initCounter = initCounter + 1
    print("NEW INITCOUNTER: \(initCounter)")
  }
  
  public override var internalRenderBlock: AUInternalRenderBlock {
    let bufferRenderParameters = self.bufferRenderParameters
    let faustItems = self.faustItems
    let initCounter = initCounter
    print("RIGHT ABOUT TO RETURN RENDER BLOCK")
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
      
     /* for i in 0 ..< Int(inputAudioBufferList.pointee.mNumberBuffers) {
        var inputBuffer = UnsafeMutableRawBufferPointer(start: mutableBuffers[i].mData, count: Int(frameCount))
        for j in 0 ..< Int(frameCount) {
          print("J: \(j), Sample: \(inputBuffer[j])")
        }
      }*/
      var err = pullInputBlock!(&pullFlags, timestamp, frameCount, 0, inputMutableAudioBufferList)
      
      if err != 0 {
        //print("PULL INPUT ERROR")
        return err
      }
      //print("NO PULL INPUT ERROR")

      let outputBuffers = UnsafeMutableBufferPointer<AudioBuffer>(start: &outputData.pointee.mBuffers, count: Int(outputData.pointee.mNumberBuffers))
      
      if (outputBuffers[0].mData == nil) {
        for i in 0 ..< Int(outputData.pointee.mNumberBuffers) {
          outputBuffers[i].mData = mutableBuffers[i].mData
        }
      }
     
      for i in 0 ..< Int(outputData.pointee.mNumberBuffers) {
        outputBuffers[i].mNumberChannels = mutableBuffers[i].mNumberChannels;
        outputBuffers[i].mDataByteSize = byteSize;
        /*var inputBuffer = UnsafeMutableRawBufferPointer(start: mutableBuffers[i].mData, count: Int(frameCount))
        var outputBuffer = UnsafeMutableRawBufferPointer(start: outputBuffers[i].mData, count: Int(frameCount))
        for i in 0 ..< Int(frameCount) {
          outputBuffer[i] = inputBuffer[i]
        }*/
        var input: UnsafeMutablePointer<Float>? = mutableBuffers[i].mData!.bindMemory(to: Float.self, capacity: Int(frameCount))
        var output: UnsafeMutablePointer<Float>? = outputBuffers[i].mData!.bindMemory(to: Float.self, capacity: Int(frameCount))
        compute_interpreter_dsp(faustItems.myDSPInterpreter, Int32(frameCount), &input, &output)
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

