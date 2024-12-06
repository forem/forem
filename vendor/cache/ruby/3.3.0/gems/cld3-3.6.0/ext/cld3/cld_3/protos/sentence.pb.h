/* Copyright 2022 Akihiko Odaki <akihiko.odaki@gmail.com>
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

#ifndef SENTENCE_PB_H_
#define SENTENCE_PB_H_

#include <string>

namespace chrome_lang_id {

class Sentence {
 public:
  const std::string& text() const { return text_; }
  void set_text(std::string value) { text_ = std::move(value); }

 private:
  std::string text_;
};

}

#endif
