# frozen_string_literal: true

module KnapsackPro
  class TestFilePresenter
    def self.stringify_paths(test_file_paths)
      test_file_paths
      .map do |test_file|
        %{"#{test_file}"}
      end.join(' ')
    end

    def self.paths(test_files)
      test_files.map { |t| t['path'] }
    end
  end
end
