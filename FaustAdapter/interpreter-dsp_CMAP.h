//
//  interpreter-dsp_CMAP.h
//  interpreter-dsp_CMAP
//
//  Created by Ryan Allan on 8/19/21.
//

#ifndef interpreter_dsp_CMAP_h
#define interpreter_dsp_CMAP_h

#include "FaustAdapter_types.h"
#include "stdbool.h"

#if __cplusplus
extern "C" {
#endif

/*int getNumInputs_interpreter_dsp(C_interpreter_dsp * dsp);

int getNumOutputs_interpreter_dsp(C_interpreter_dsp * dsp);

int getSampleRate_interpreter_dsp(C_interpreter_dsp * dsp);*/

void init_interpreter_dsp(C_interpreter_dsp * dsp, int sample_rate);

//void instanceInit_interpreter_dsp(C_interpreter_dsp * dsp, int sample_rate);

/*void instanceConstants_interpreter_dsp(C_interpreter_dsp * dsp, int sample_rate);

void instanceClear_interpreter_dsp(C_interpreter_dsp * dsp);

C_interpreter_dsp * clone_interpreter_dsp(C_interpreter_dsp * dsp);*/

void compute_interpreter_dsp(C_interpreter_dsp * dsp, int count, float ** input, float ** output);

C_interpreter_dsp * createDSPInstance_C_interpreter_dsp_factory(C_interpreter_dsp_factory * factory);

C_interpreter_dsp_factory * C_createInterpreterDSPFactoryFromString(const char * name_app, const char * dsp_content, int argc, const char* argv[]);

bool C_deleteInterpreterDSPFactory(C_interpreter_dsp_factory * factory);

#if __cplusplus
}
#endif


#endif /* interpreter_dsp_CMAP_h */
