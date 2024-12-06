# frozen_string_literal: true

module I18n::Tasks
  module Command
    module OptionParsers
      module Enum
        class Parser
          DEFAULT_ERROR = proc do |invalid, valid|
            I18n.t('i18n_tasks.cmd.enum_opt.invalid', invalid: invalid, valid: valid * ', ')
          end

          def initialize(valid, error_message = DEFAULT_ERROR)
            @valid         = valid.map(&:to_s)
            @error_message = error_message
          end

          def call(value, *)
            return @valid.first unless value.present?

            if @valid.include?(value)
              value
            else
              fail CommandError, @error_message.call(value, @valid)
            end
          end
        end

        class ListParser
          DEFAULT_ERROR = proc do |invalid, valid|
            I18n.t('i18n_tasks.cmd.enum_list_opt.invalid', invalid: invalid * ', ', valid: valid * ', ')
          end

          def initialize(valid, error_message = DEFAULT_ERROR)
            @valid         = valid.map(&:to_s)
            @error_message = error_message
          end

          def call(values, *)
            values = Array(values)
            return @valid if values == %w[all]

            invalid = values - @valid
            if invalid.empty?
              if values.empty?
                @valid
              else
                values
              end
            else
              fail CommandError, @error_message.call(invalid, @valid)
            end
          end
        end
      end
    end
  end
end
