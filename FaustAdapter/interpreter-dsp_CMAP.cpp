//
//  interpreter-dsp_CMAP.cpp
//  interpreter-dsp_CMAP
//
//  Created by Ryan Allan on 8/19/21.
//

#include "interpreter-dsp_CMAP.h"
#include "faust/dsp/interpreter-dsp.h"
#include <string>
#include<iostream>

extern "C" {

/*int getNumInputs_interpreter_dsp(C_interpreter_dsp * dsp);

int getNumOutputs_interpreter_dsp(C_interpreter_dsp * dsp);

int getSampleRate_interpreter_dsp(C_interpreter_dsp * dsp);*/

void init_interpreter_dsp(C_interpreter_dsp * dsp, int sample_rate) {
  reinterpret_cast<interpreter_dsp *>(dsp)->init(sample_rate);
}

//void instanceInit_interpreter_dsp(C_interpreter_dsp * dsp, int sample_rate);

/*void instanceConstants_interpreter_dsp(C_interpreter_dsp * dsp, int sample_rate);

void instanceClear_interpreter_dsp(C_interpreter_dsp * dsp);

C_interpreter_dsp * clone_interpreter_dsp(C_interpreter_dsp * dsp);*/

void compute_interpreter_dsp(C_interpreter_dsp * dsp, int count, float ** input, float ** output) {
  reinterpret_cast<interpreter_dsp *>(dsp)->compute(count, input, output);
}

C_interpreter_dsp * createDSPInstance_C_interpreter_dsp_factory(C_interpreter_dsp_factory * factory) {
  return reinterpret_cast<C_interpreter_dsp *>(reinterpret_cast<interpreter_dsp_factory *>(factory)->createDSPInstance());
}

C_interpreter_dsp_factory * C_createInterpreterDSPFactoryFromString(const char * name_app, const char * dsp_content, int argc, const char* argv[]) {
  const std::string name(name_app);
  const std::string content(dsp_content);
  std::string dummy("test");
  //std::cout << content << std::endl;
  C_interpreter_dsp_factory * ans = reinterpret_cast<C_interpreter_dsp_factory *>(createInterpreterDSPFactoryFromString(name, content, argc, argv, dummy));
  //std::cout << dummy << std::endl;
  return ans;
}

bool C_deleteInterpreterDSPFactory(C_interpreter_dsp_factory * factory) {
  return deleteInterpreterDSPFactory(reinterpret_cast<interpreter_dsp_factory *>(factory));
}

}
