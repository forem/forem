# frozen_string_literal: true

module ERBLint
  class Corrector
    attr_reader :processed_source, :offenses, :corrected_content

    def initialize(processed_source, offenses)
      @processed_source = processed_source
      @offenses = offenses
      @corrected_content = corrector.rewrite
    end

    def corrections
      @corrections ||= @offenses.map do |offense|
        offense.linter.autocorrect(@processed_source, offense)
      end.compact
    end

    def corrector
      BASE.new(@processed_source.source_buffer, corrections)
    end

    if ::RuboCop::Version::STRING.to_f >= 0.87
      require 'rubocop/cop/legacy/corrector'
      BASE = ::RuboCop::Cop::Legacy::Corrector

      def diagnostics
        []
      end
    else
      BASE = ::RuboCop::Cop::Corrector

      def diagnostics
        corrector.diagnostics
      end
    end
  end
end
