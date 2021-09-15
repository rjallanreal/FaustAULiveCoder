//
//  FaustAULiveCoderExtensionAudioUnit.h
//  FaustAULiveCoderExtension
//
//  Created by Ryan Allan on 8/19/21.
//

#import <AudioToolbox/AudioToolbox.h>
#import "FaustAULiveCoderExtensionDSPKernelAdapter.h"

// Define parameter addresses.
extern const AudioUnitParameterID myParam1;

@interface FaustAULiveCoderExtensionAudioUnit : AUAudioUnit

@property (nonatomic, readonly) FaustAULiveCoderExtensionDSPKernelAdapter *kernelAdapter;
- (void)setupAudioBuses;
- (void)setupParameterTree;
- (void)setupParameterCallbacks;
@end
