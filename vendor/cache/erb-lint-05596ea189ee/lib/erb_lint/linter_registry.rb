# frozen_string_literal: true

module ERBLint
  # Stores all linters available to the application.
  module LinterRegistry
    CUSTOM_LINTERS_DIR = '.erb-linters'
    @loaded_linters = []

    class << self
      def clear
        @linters = nil
      end

      def included(linter_class)
        @loaded_linters << linter_class
      end

      def find_by_name(name)
        linters.detect { |linter| linter.simple_name == name }
      end

      def linters
        @linters ||= begin
          load_custom_linters
          @loaded_linters
        end
      end

      def load_custom_linters(directory = CUSTOM_LINTERS_DIR)
        ruby_files = Dir.glob(File.expand_path(File.join(directory, '**', '*.rb')))
        ruby_files.each { |file| require file }
      end
    end
  end
end
