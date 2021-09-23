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

void init_faust_dsp(C_faust_dsp * dsp, int sample_rate) {
  reinterpret_cast<interpreter_dsp *>(dsp)->init(sample_rate);
}

//void instanceInit_interpreter_dsp(C_interpreter_dsp * dsp, int sample_rate);

/*void instanceConstants_interpreter_dsp(C_interpreter_dsp * dsp, int sample_rate);

void instanceClear_interpreter_dsp(C_interpreter_dsp * dsp);

C_interpreter_dsp * clone_interpreter_dsp(C_interpreter_dsp * dsp);*/

void faust_compute(C_faust_dsp * dsp, int count, float ** input, float ** output) {
  reinterpret_cast<interpreter_dsp *>(dsp)->compute(count, input, output);
}

int faust_dsp_inputs(C_faust_dsp * dsp) {
  return reinterpret_cast<interpreter_dsp *>(dsp)->getNumInputs();
}

int faust_dsp_outputs(C_faust_dsp * dsp) {
  return reinterpret_cast<interpreter_dsp *>(dsp)->getNumOutputs();
}

C_faust_dsp * create_faust_dsp(C_faust_factory * factory) {
  return reinterpret_cast<C_faust_dsp *>(reinterpret_cast<interpreter_dsp_factory *>(factory)->createDSPInstance());
}

C_faust_factory * create_faust_factory_from_string(const char * name_app, const char * dsp_content, int argc, const char* argv[], char ** error_msg) {
  const std::string name(name_app);
  const std::string content(dsp_content);
  std::string errorString("");
  C_faust_factory * ans = reinterpret_cast<C_faust_factory *>(createInterpreterDSPFactoryFromString(name, content, argc, argv, errorString));
  
  int n = errorString.length();
  char * new_error_msg = (char *) malloc((n+1) * sizeof(char));
  strcpy(new_error_msg, errorString.c_str());
  *error_msg = new_error_msg;
  
  return ans;
}

bool delete_faust_factory(C_faust_factory * factory) {
  return deleteInterpreterDSPFactory(reinterpret_cast<interpreter_dsp_factory *>(factory));
}

}
