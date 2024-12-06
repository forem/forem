# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module TextDocument
        class Hover < Base
          def process
            line = params['position']['line']
            col = params['position']['character']
            contents = []
            suggestions = host.definitions_at(params['textDocument']['uri'], line, col)
            last_link = nil
            suggestions.each do |pin|
              parts = []
              this_link = host.options['enablePages'] ? pin.link_documentation : pin.text_documentation
              if !this_link.nil? && this_link != last_link
                parts.push this_link
              end
              parts.push "`#{pin.detail}`" unless pin.is_a?(Pin::Namespace) || pin.detail.nil?
              parts.push pin.documentation unless pin.documentation.nil? || pin.documentation.empty?
              unless parts.empty?
                data = parts.join("\n\n")
                next if contents.last && contents.last.end_with?(data)
                contents.push data
              end
              last_link = this_link unless this_link.nil?
            end
            set_result(
              contents_or_nil(contents)
            )
          rescue FileNotFoundError => e
            Logging.logger.warn "[#{e.class}] #{e.message}"
            Logging.logger.warn e.backtrace.join("\n")
            set_result nil
          end

          private

          def contents_or_nil contents
            stripped = contents
              .map(&:strip)
              .reject { |c| c.empty? }
            return nil if stripped.empty?
            {
              contents: {
                kind: 'markdown',
                value: stripped.join("\n\n")
              }
            }
          end
        end
      end
    end
  end
end
