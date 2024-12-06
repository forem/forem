# frozen_string_literal: true

require 'json'

module I18n::Tasks
  module Data
    module Adapter
      module JsonAdapter
        class << self
          # @return [Hash] locale tree
          def parse(str, opts)
            JSON.parse(str, parse_opts(opts))
          end

          # @return [String]
          def dump(tree, opts)
            JSON.generate(tree, parse_opts(opts))
          end

          private

          def parse_opts(opts)
            opts.try(:symbolize_keys) || {}
          end
        end
      end
    end
  end
end
