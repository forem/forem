# File including an implementation of CLD3 module. Some documentations are
# extracted from ext/cld3/ext/src/nnet_language_identifier.h.
#
# Copyright 2017 Akihiko Odaki <akihiko.odaki@gmail.com>
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ==============================================================================

# Module providing an interface for Compact Language Detector v3 (CLD3)
module CLD3
  # Class for detecting the language of a document.
  class NNetLanguageIdentifier
    # Holds probability that Span, specified by start/end indices, is a given
    # language. The langauge is not stored here; it can be found in Result, which
    # holds an Array of SpanInfo.
    # @type const SpanInfo: untyped
    SpanInfo = Struct.new(:start_index, :end_index, :probability)

    # Information about a predicted language.
    # This is an instance of Struct with the following members:
    #
    # [language]    This is symbol.
    #
    # [probability] Language probability. This is Numeric object.
    #
    # [reliable?]   Whether the prediction is reliable. This is true or false.
    #
    # [proportion]  Proportion of bytes associated with the language. If
    #               #find_language is called, this variable is set to 1.
    #               This is Numeric object.
    #
    # [byte_ranges] Specifies the byte ranges in UTF-8 that |language| applies to.
    #               This is an Array of SpanInfo.
    # @type const Result: untyped
    Result = Struct.new(:language, :probability, :reliable?, :proportion, :byte_ranges)

    # The arguments are two Numeric objects.
    def initialize(min_num_bytes = MIN_NUM_BYTES_TO_CONSIDER, max_num_bytes = MAX_NUM_BYTES_TO_CONSIDER)
      min_num_bytes = min_num_bytes.ceil
      max_num_bytes = max_num_bytes.floor
      raise ArgumentError if min_num_bytes < 0 || min_num_bytes >= max_num_bytes
      @cc = Unstable.make(min_num_bytes, max_num_bytes)
    end

    # Finds the most likely language for the given text, along with additional
    # information (e.g., probability). The prediction is based on the first N
    # bytes where N is the minimum between the number of interchange valid UTF8
    # bytes and +max_num_bytes_+. If N is less than +min_num_bytes_+ long, then
    # this function returns nil.
    # The argument is a String object.
    # The returned value of this function is an instance of Result.
    def find_language(text)
      @cc.find_language(Result, SpanInfo, text.encode(Encoding::UTF_8))
    end

    # Splits the input text (up to the first byte, if any, that is not
    # interchange valid UTF8) into spans based on the script, predicts a language
    # for each span, and returns a vector storing the top num_langs most frequent
    # languages along with additional information (e.g., proportions). The number
    # of bytes considered for each span is the minimum between the size of the
    # span and +max_num_bytes_+. If more languages are requested than what is
    # available in the input, then the number of the returned elements will be
    # the number of the latter. Also, if the size of the span is less than
    # +min_num_bytes_+ long, then the span is skipped. If the input text is too
    # long, only the first +MAX_NUM_INPUT_BYTES_TO_CONSIDER+ bytes are processed.
    # The first argument is a String object.
    # The second argument is Numeric object.
    # The returned value of this functions is an Array of Result instances.
    def find_top_n_most_freq_langs(text, num_langs)
      @cc.find_top_n_most_freq_langs(Result, SpanInfo,
                                     text.encode(Encoding::UTF_8),
                                     num_langs)
    end

    class Unstable
    end
  
    private_constant :Unstable
  end

  # Encapsulates the TaskContext specifying only the parameters for the model.
  # The model weights are loaded statically.
  module TaskContextParams
    # This is an frozen Array object containing symbols.
    # @type const LANGUAGE_NAMES: untyped
    LANGUAGE_NAMES = []
  end
end

require "cld3_ext"
CLD3::TaskContextParams::LANGUAGE_NAMES.freeze
