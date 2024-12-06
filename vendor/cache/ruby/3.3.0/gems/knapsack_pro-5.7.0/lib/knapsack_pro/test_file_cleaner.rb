# frozen_string_literal: true

module KnapsackPro
  class TestFileCleaner
    def self.clean(test_file_path)
      test_file_path.sub(/^\.\//, '')
    end
  end
end
