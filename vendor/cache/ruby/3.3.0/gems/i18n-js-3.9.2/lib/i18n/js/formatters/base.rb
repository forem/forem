module I18n
  module JS
    module Formatters
      class Base
        def initialize(js_extend: false, namespace: nil, pretty_print: false, prefix: nil, suffix: nil)
          @js_extend    = js_extend
          @namespace    = namespace
          @pretty_print = pretty_print
          @prefix = prefix
          @suffix = suffix
        end

        protected

        def format_json(translations)
          if @pretty_print
            ::JSON.pretty_generate(translations)
          else
            translations.to_json
          end
        end
      end
    end
  end
end
