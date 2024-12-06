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

#ifndef TASK_SPEC_PB_H_
#define TASK_SPEC_PB_H_

#include <string>
#include <vector>

namespace chrome_lang_id {

class TaskInput {
 public:
  class Part {
   public:
    const std::string& file_pattern() const { return file_pattern_; }

   private:
    std::string file_pattern_;
  };

  const std::string& name() const { return name_; }

  void set_name(std::string value) { name_ = value; }

  int file_format_size() const { return file_format_.size(); }

  const std::string& file_format(int index) const {
    return file_format_[index];
  }

  void add_file_format(std::string value) {
    file_format_.push_back(std::move(value));
  }

  int record_format_size() const { return record_format_.size(); }

  const std::string& record_format(int index) const {
    return record_format_[index];
  }

  void add_record_format(std::string value) {
    record_format_.push_back(std::move(value));
  }

  int part_size() const { return part_.size(); }
  const Part& part(int index) const { return part_[index]; }

 private:
  std::string name_;
  std::vector<std::string> file_format_;
  std::vector<std::string> record_format_;
  std::vector<Part> part_;
};

class TaskSpec {
 public:
  class Parameter {
   public:
    const std::string& name() const { return name_; }
    void set_name(std::string value) { name_ = std::move(value); }
    const std::string& value() const { return value_; }
    void set_value(std::string value) { value_ = std::move(value); }

   private:
    std::string name_;
    std::string value_;
  };

  int parameter_size() const { return parameter_.size(); }

  Parameter* mutable_parameter(int index) { return &parameter_[index]; }

  const Parameter& parameter(int index) const { return parameter_[index]; }

  Parameter* add_parameter() { return &parameter_.emplace_back(); }

  int input_size() const { return input_.size(); }

  TaskInput* mutable_input(int index) { return &input_[index]; }

  const TaskInput& input(int index) const { return input_[index]; }

  TaskInput* add_input() { return &input_.emplace_back(); }

 private:
  std::vector<Parameter> parameter_;
  std::vector<TaskInput> input_;
};

}

#endif
