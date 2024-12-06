# frozen_string_literal: true

module KnapsackPro
  class TestFilePattern
    def self.call(adapter_class)
      KnapsackPro::Config::Env.test_file_pattern || adapter_class::TEST_DIR_PATTERN
    end

    def self.test_dir(adapter_class)
      test_file_pattern = call(adapter_class)
      test_file_pattern.split('/').first.gsub(/({)/, '')
    end
  end
end
