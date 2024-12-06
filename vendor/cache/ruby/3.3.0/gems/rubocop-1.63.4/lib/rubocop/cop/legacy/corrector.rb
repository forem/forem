# frozen_string_literal: true

module RuboCop
  module Cop
    module Legacy
      # Legacy Corrector for v0 API support.
      # See https://docs.rubocop.org/rubocop/v1_upgrade_notes.html
      class Corrector < RuboCop::Cop::Corrector
        # Support legacy second argument
        def initialize(source, corr = [])
          super(source)
          if corr.is_a?(CorrectionsProxy)
            merge!(corr.send(:corrector))
          else
            # warn "Corrector.new with corrections is deprecated." unless corr.empty? TODO
            corr.each { |c| corrections << c }
          end
        end

        def corrections
          # warn "#corrections is deprecated. Open an issue if you have a valid usecase." TODO
          CorrectionsProxy.new(self)
        end
      end
    end
  end
end
