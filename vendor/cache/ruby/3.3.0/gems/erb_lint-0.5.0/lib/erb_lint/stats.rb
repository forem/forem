# frozen_string_literal: true

module ERBLint
  class Stats
    attr_accessor :ignored,
      :found,
      :corrected,
      :exceptions,
      :linters,
      :autocorrectable_linters,
      :files,
      :processed_files

    def initialize(
      ignored: 0,
      found: 0,
      corrected: 0,
      exceptions: 0,
      linters: 0,
      autocorrectable_linters: 0,
      files: 0,
      processed_files: {}
    )
      @ignored = ignored
      @found = found
      @corrected = corrected
      @exceptions = exceptions
      @linters = linters
      @autocorrectable_linters = autocorrectable_linters
      @files = files
      @processed_files = processed_files
    end
  end
end
