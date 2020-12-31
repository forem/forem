# frozen_string_literal: true

module ERBLint
  module Linters
    class CustomLinter < Linter
      include LinterRegistry
    end
  end
end
