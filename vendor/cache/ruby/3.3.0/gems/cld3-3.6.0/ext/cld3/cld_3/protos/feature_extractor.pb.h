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

#ifndef FEATURE_EXTRACTOR_PB_H_
#define FEATURE_EXTRACTOR_PB_H_

#include <cstdint>
#include <string>
#include <vector>

namespace chrome_lang_id {

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

class FeatureFunctionDescriptor {
 public:
  const std::string& type() const { return type_; }

  void set_type(std::string value) { type_ = std::move(value); }

  const std::string& name() const { return name_; }

  void set_name(std::string value) { name_ = std::move(value); }

  bool has_argument() const { return true; }

  std::int32_t argument() const { return argument_; }

  void set_argument(int32_t value) { argument_ = value; }

  int parameter_size() const { return parameter_.size(); }

  const Parameter& parameter(int index) const { return parameter_[index]; }

  Parameter* add_parameter() { return &parameter_.emplace_back(); }

  int feature_size() const { return feature_.size(); }

  FeatureFunctionDescriptor* mutable_feature(int index) {
    return &feature_[index];
  }

  const FeatureFunctionDescriptor& feature(int index) const {
    return feature_[index];
  }

  FeatureFunctionDescriptor* add_feature() { return &feature_.emplace_back(); }

 private:
  std::string type_;
  std::string name_;
  std::int32_t argument_;
  std::vector<Parameter> parameter_;
  std::vector<FeatureFunctionDescriptor> feature_;
};

class FeatureExtractorDescriptor {
 public:
  int feature_size() const { return feature_.size(); }

  FeatureFunctionDescriptor* mutable_feature(int index) {
    return &feature_[index];
  }

  const FeatureFunctionDescriptor& feature(int index) const {
    return feature_[index];
  }

  FeatureFunctionDescriptor* add_feature() { return &feature_.emplace_back(); }

 private:
  std::vector<FeatureFunctionDescriptor> feature_;
};

}

#endif
