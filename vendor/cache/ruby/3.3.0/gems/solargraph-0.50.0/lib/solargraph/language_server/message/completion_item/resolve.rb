# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module CompletionItem
        # completionItem/resolve message handler
        #
        class Resolve < Base
          def process
            pins = host.locate_pins(params)
            set_result merge(pins)
          end

          private

          # @param pins [Array<Pin::Base>]
          # @return [Hash]
          def merge pins
            return params if pins.empty?
            docs = pins
                   .reject { |pin| pin.documentation.empty? && pin.return_type.undefined? }
            result = params
              .transform_keys(&:to_sym)
              .merge(pins.first.resolve_completion_item)
              .merge(documentation: markup_content(join_docs(docs)))
            result[:detail] = pins.first.detail
            result
          end

          # @param text [String]
          # @return [Hash{Symbol => String}]
          def markup_content text
            return nil if text.strip.empty?
            {
              kind: 'markdown',
              value: text
            }
          end

          def join_docs pins
            result = []
            last_link = nil
            pins.each_with_index do |pin|
              this_link = host.options['enablePages'] ? pin.link_documentation : pin.text_documentation
              if this_link && this_link != last_link && this_link != 'undefined'
                result.push this_link
              end
              result.push pin.documentation unless result.last && result.last.end_with?(pin.documentation)
              last_link = this_link
            end
            result.join("\n\n")
          end
        end
      end
    end
  end
end
