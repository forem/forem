require "i18n/js/formatters/base"

module I18n
  module JS
    module Formatters
      class JSON < Base
        def format(translations)
          format_json(translations)
        end
      end
    end
  end
end
