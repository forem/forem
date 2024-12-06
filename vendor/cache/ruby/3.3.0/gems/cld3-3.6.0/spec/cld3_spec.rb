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
#==============================================================================

require "bundler/setup"
Bundler.setup

require "rbs/test/setup"
require "cld3"

describe CLD3::NNetLanguageIdentifier do
  describe "#initialize" do
    it "is expected to raise ArgumentError with negative min_num_bytes" do
      expect { described_class.new(-1, 1000) }.to raise_error(ArgumentError)
    end

    it "is expected to raise ArgumentError with min_num_bytes <= max_num_bytes" do
      expect { described_class.new(0, 0) }.to raise_error(ArgumentError)
    end
  end

  context "initialized without parameters" do
    let(:lang_id) { described_class.new }

    describe "#find_language" do
      subject { lang_id.find_language("This text is written in English.") }
      it { is_expected.to be_nil }
    end
  end

  # See ext/cld3/ext/src/language_identifier_main.cc
  context "initialized with custom parameters" do
    let(:lang_id) { described_class.new(0, 1000) }

    describe "#find_language" do
      subject { lang_id.find_language text }

      context "with an English text" do
        let(:text) { "This text is written in English." }
        it {
          is_expected.to satisfy { |result|
            result.language == :en &&
            result.probability > 0 &&
            result.probability < 1 &&
            result.reliable? &&
            result.proportion == 1 &&
            result.byte_ranges == []
          }
        }
      end
    end

    describe "#find_top_n_most_freq_langs" do
      subject { lang_id.find_top_n_most_freq_langs text, 3 }

      context "with an English text followed by a Russian text" do
        let(:text) { "This piece of text is in English. Този текст е на Български." }
        it {
          is_expected.to satisfy { |results|
            results.size == 2 &&
            results[0].language == :bg &&
            results[0].probability > 0 &&
            results[0].probability < 1 &&
            results[0].reliable? &&
            results[0].proportion > 0 &&
            results[0].proportion < 1 &&
            results[0].byte_ranges.size == 1 &&
            results[0].byte_ranges[0].start_index == 34 &&
            results[0].byte_ranges[0].end_index == 81 &&
            results[0].byte_ranges[0].probability == results[0].probability &&
            results.size == 2 &&
            results[1].language == :en &&
            results[1].probability > 0 &&
            results[1].probability < 1 &&
            results[1].reliable? &&
            results[1].proportion > 0 &&
            results[1].proportion < 1 &&
            results[1].byte_ranges.size == 1 &&
            results[1].byte_ranges[0].start_index == 0 &&
            results[1].byte_ranges[0].end_index == 34 &&
            results[1].byte_ranges[0].probability == results[1].probability
          }
        }
      end
    end
  end
end
