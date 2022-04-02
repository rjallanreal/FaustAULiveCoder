//
//  interpreter-dsp_CMAP.cpp
//  interpreter-dsp_CMAP
//
//  Created by Ryan Allan on 8/19/21.
//

#include "dsp_CMAP.h"
#include "faust/dsp/dsp.h"
#include "faust/dsp/llvm-dsp.h"
#include <string>
#include<iostream>

extern "C" {

/*int getNumInputs_interpreter_dsp(C_interpreter_dsp * dsp);

int getNumOutputs_interpreter_dsp(C_interpreter_dsp * dsp);

int getSampleRate_interpreter_dsp(C_interpreter_dsp * dsp);*/

void __attribute__((visibility("default"))) init_faust_dsp(C_faust_dsp * dsp, int sample_rate) {
  reinterpret_cast<class dsp *>(dsp)->init(sample_rate);
}

//void instanceInit_interpreter_dsp(C_interpreter_dsp * dsp, int sample_rate);

/*void instanceConstants_interpreter_dsp(C_interpreter_dsp * dsp, int sample_rate);

void instanceClear_interpreter_dsp(C_interpreter_dsp * dsp);

C_interpreter_dsp * clone_interpreter_dsp(C_interpreter_dsp * dsp);*/

void __attribute__((visibility("default"))) faust_compute(struct C_faust_dsp * dsp, int count, float ** input, float ** output) {
  reinterpret_cast<class dsp *>(dsp)->compute(count, input, output);
}

int __attribute__((visibility("default"))) faust_dsp_inputs(struct C_faust_dsp * dsp) {
  return reinterpret_cast<class dsp *>(dsp)->getNumInputs();
}

int __attribute__((visibility("default"))) faust_dsp_outputs(struct C_faust_dsp * dsp) {
  return reinterpret_cast<class dsp *>(dsp)->getNumOutputs();
}

C_faust_dsp * __attribute__((visibility("default"))) create_faust_dsp(C_faust_factory * factory) {
  return reinterpret_cast<C_faust_dsp *>(reinterpret_cast<dsp_factory *>(factory)->createDSPInstance());
}

C_faust_factory * __attribute__((visibility("default"))) create_faust_factory_from_string(const char * name_app, const char * dsp_content, int argc, const char* argv[], char ** error_msg) {
  const std::string name(name_app);
  const std::string content(dsp_content);
  std::string errorString("");
  C_faust_factory * ans = reinterpret_cast<C_faust_factory *>(createDSPFactoryFromString(name, content, argc, argv, "", errorString));
  
  int n = errorString.length();
  char * new_error_msg = (char *) malloc((n+1) * sizeof(char));
  strcpy(new_error_msg, errorString.c_str());
  *error_msg = new_error_msg;
  
  return ans;
}

bool __attribute__((visibility("default"))) delete_faust_factory(C_faust_factory * factory) {
  return deleteDSPFactory(reinterpret_cast<llvm_dsp_factory *>(factory));
}

}
