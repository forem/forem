/* Copyright 2017 Akihiko Odaki <akihiko.odaki@gmail.com>
All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
==============================================================================*/

#include <cstddef>
#include <iostream>
#include <string>
#include <utility>
#include <ruby.h>
#include "nnet_language_identifier.h"

#if defined _WIN32 || defined __CYGWIN__
  #define EXPORT __declspec(dllexport)
#else
  #define EXPORT __attribute__((visibility("default")))
#endif

struct Result {
  VALUE result_klass;
  VALUE span_info_klass;
  const chrome_lang_id::NNetLanguageIdentifier::Result& data;

  VALUE convert() const {
    if (data.language == chrome_lang_id::NNetLanguageIdentifier::kUnknown)
      return Qnil;

    VALUE byte_ranges = rb_ary_new2(data.byte_ranges.size());
    for (auto& byte_range_data : data.byte_ranges) {
      VALUE argv[] = {
        INT2NUM(byte_range_data.start_index),
        INT2NUM(byte_range_data.end_index),
        DBL2NUM(byte_range_data.probability),
      };

      VALUE byte_range = rb_class_new_instance(sizeof(argv) / sizeof(*argv),
                                               argv,
                                               span_info_klass);
      rb_ary_push(byte_ranges, byte_range);
    }

    VALUE argv[] = {
      ID2SYM(rb_intern2(data.language.data(), data.language.size())),
      DBL2NUM(data.probability),
      data.is_reliable ? Qtrue : Qfalse,
      DBL2NUM(data.proportion),
      byte_ranges,
    };

    return rb_class_new_instance(sizeof(argv) / sizeof(*argv), argv,
                                 result_klass);
  }
};

struct ResultVector {
  VALUE result_klass;
  VALUE span_info_klass;
  VALUE buffer;
  const std::vector<chrome_lang_id::NNetLanguageIdentifier::Result>& data;

  VALUE convert() const {
    for (auto& element_data : data) {
      Result result { result_klass, span_info_klass, element_data };
      VALUE element = result.convert();
      if (element == Qnil)
        break;

      rb_ary_push(buffer, element);
    }

    return buffer;
  }
};

template<typename T>
VALUE convert_protected(VALUE arg) {
  auto result = reinterpret_cast<const T *>(arg);
  return result->convert();
}

static void dfree(void *arg) {
  auto data = static_cast<chrome_lang_id::NNetLanguageIdentifier *>(arg);
  data->~NNetLanguageIdentifier();
  xfree(arg);
}

static size_t dsize(const void *data) {
  return sizeof(chrome_lang_id::NNetLanguageIdentifier);
}

static const rb_data_type_t data_type = {
  "CLD3::NNetLanguageIdentifier", { nullptr, dfree, dsize }, nullptr, nullptr,
  RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE find_language(VALUE obj,
                           VALUE result_klass, VALUE span_info_klass,
                           VALUE text) {
  int state;
  VALUE converted;

  {
    chrome_lang_id::NNetLanguageIdentifier *data;
    TypedData_Get_Struct(obj, chrome_lang_id::NNetLanguageIdentifier,
                         &data_type, data);
    std::string text_string = std::string(RSTRING_PTR(text), RSTRING_LEN(text));
    auto result_data = data->FindLanguage(text_string);
    Result result { result_klass, span_info_klass, result_data };

    converted = rb_protect(convert_protected<Result>,
                           reinterpret_cast<VALUE>(&result),
                           &state);
  }

  if (state)
    rb_jump_tag(state);

  return converted;
}

static VALUE find_top_n_most_freq_langs(VALUE obj,
                                        VALUE result_klass,
                                        VALUE span_info_klass,
                                        VALUE text,
                                        VALUE num_langs) {
  int state;
  VALUE converted;

  {
    chrome_lang_id::NNetLanguageIdentifier *data;
    TypedData_Get_Struct(obj, chrome_lang_id::NNetLanguageIdentifier,
                         &data_type, data);
    VALUE buffer = rb_ary_new2(NUM2INT(num_langs));
    std::string text_string = std::string(RSTRING_PTR(text), RSTRING_LEN(text));
    auto result_data = data->FindTopNMostFreqLangs(text_string, num_langs);
    ResultVector result { result_klass, span_info_klass, buffer, result_data };

    converted = rb_protect(convert_protected<ResultVector>,
                           reinterpret_cast<VALUE>(&result),
                           &state);
  }

  if (state)
    rb_jump_tag(state);

  return converted;
}

static VALUE make(VALUE klass, VALUE min_num_bytes, VALUE max_num_bytes) {
  int min_num_bytes_int = NUM2INT(min_num_bytes);
  int max_num_bytes_int = NUM2INT(max_num_bytes);
  chrome_lang_id::NNetLanguageIdentifier *data;
  VALUE value = TypedData_Make_Struct(klass,
                                      chrome_lang_id::NNetLanguageIdentifier,
                                      &data_type, data);
  new (data) chrome_lang_id::NNetLanguageIdentifier(min_num_bytes_int, max_num_bytes_int);
  return value;
}

extern "C" EXPORT void Init_cld3_ext() {
  VALUE cld3 = rb_const_get(rb_cObject, rb_intern("CLD3"));
  VALUE identifier = 
    rb_const_get(cld3, rb_intern("NNetLanguageIdentifier"));
  VALUE unstable = rb_const_get(identifier, rb_intern("Unstable"));
  VALUE params = rb_const_get(cld3, rb_intern("TaskContextParams"));
  VALUE language_names = rb_const_get(params, rb_intern("LANGUAGE_NAMES"));

  rb_define_const(identifier, "MIN_NUM_BYTES_TO_CONSIDER",
                  INT2NUM(chrome_lang_id::NNetLanguageIdentifier::kMinNumBytesToConsider));
  rb_define_const(identifier, "MAX_NUM_BYTES_TO_CONSIDER",
                  INT2NUM(chrome_lang_id::NNetLanguageIdentifier::kMaxNumBytesToConsider));
  rb_define_const(identifier, "MAX_NUM_INPUT_BYTES_TO_CONSIDER",
                  INT2NUM(chrome_lang_id::NNetLanguageIdentifier::kMaxNumInputBytesToConsider));
  rb_define_const(identifier, "RELIABILITY_THRESHOLD",
                  DBL2NUM(chrome_lang_id::NNetLanguageIdentifier::kReliabilityThreshold));
  rb_define_const(identifier, "RELIABILITY_HR_BS_THRESHOLD",
                  DBL2NUM(chrome_lang_id::NNetLanguageIdentifier::kReliabilityHrBsThreshold));

  rb_undef_alloc_func(unstable);
  rb_define_singleton_method(unstable, "make", make, 2);
  rb_define_method(unstable, "find_language", find_language, 3);
  rb_define_method(unstable, "find_top_n_most_freq_langs",
                   find_top_n_most_freq_langs, 4);

  for (int i = 0; ; i++) {
    const char *name = chrome_lang_id::TaskContextParams::language_names(i);
    if (!name)
      break;

    rb_ary_push(language_names, ID2SYM(rb_intern(name)));
  }
}
