# frozen_string_literal: true

module I18n::Tasks
  module Command
    module OptionParsers
      module Locale
        module Validator
          VALID_LOCALE_RE = /\A\w[\w\-.]*\z/i.freeze

          def validate!(locale)
            if VALID_LOCALE_RE !~ locale
              fail CommandError, I18n.t('i18n_tasks.cmd.errors.invalid_locale', invalid: locale)
            end

            locale
          end
        end

        module Parser
          module_function

          extend Validator

          # @param [#base_locale, #locales] context
          def call(val, context)
            if val.blank? || val == 'base'
              context.base_locale
            else
              validate! val
            end
          end
        end

        module ListParser
          module_function

          extend Validator

          # @param [#base_locale,#locales] context
          def call(vals, context)
            if vals == %w[all] || vals.blank?
              context.locales
            else
              move_base_locale_to_front!(vals.map { |v| v == 'base' ? context.base_locale : v }, context.base_locale)
            end.tap do |locales|
              locales.each { |locale| validate! locale }
            end
          end

          def move_base_locale_to_front!(locales, base_locale)
            if (pos = locales.index(base_locale)) && pos.positive?
              locales[pos], locales[0] = locales[0], locales[pos]
            end
            locales
          end
        end
      end
    end
  end
end
