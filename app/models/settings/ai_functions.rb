module Settings
  ##
  # Stores which model powers each AI function (see Ai::FunctionRegistry).
  #
  # All selections live in one hash setting, `function_models`, mapping a function key to a
  # model option key (see Ai::FunctionConfig::OPTIONS). A missing key means "default", i.e.
  # the function's built-in Gemini behavior.
  #
  # Unlike most settings this one is always global: AI functions mostly run in Sidekiq, where
  # there is no request subforem, so a subforem-scoped row would silently never apply.
  class AiFunctions < Base
    self.table_name = :settings_ai_functions

    setting :function_models, type: :hash, default: {}
    # Minimum Jev probability at which content without links is escalated to the spam checks
    # (see Ai::SpamEscalationCheck). Lower catches more spam at the cost of more spam checks.
    setting :spam_escalation_threshold, type: :float, default: 0.3,
                                        validates: { numericality: { greater_than: 0, less_than_or_equal_to: 1 } }

    class << self
      # @return [HashWithIndifferentAccess] function key => option key, global rows only.
      def global_function_models
        raw = all_settings(nil)["function_models"]
        convert_string_to_value_type(:hash, raw.presence || {}).to_h.with_indifferent_access
      end

      # @return [String, nil] The configured option key for a function, if any.
      def function_model(function_key)
        global_function_models[function_key.to_s].presence
      end

      # @return [Float] The global escalation threshold, or its default.
      def global_spam_escalation_threshold
        raw = all_settings(nil)["spam_escalation_threshold"]
        raw.present? ? convert_string_to_value_type(:float, raw) : get_default(:spam_escalation_threshold)
      end

      def set_global_spam_escalation_threshold(value)
        record = find_by(var: "spam_escalation_threshold", subforem_id: nil) ||
          new(var: "spam_escalation_threshold", subforem_id: nil)
        record.value = value
        record.save!
        clear_cache
        value
      end

      # Replaces the stored selections. Keys and values are validated by the caller
      # (Ai::FunctionConfig.sanitize).
      def set_global_function_models(selections)
        record = find_by(var: "function_models", subforem_id: nil) || new(var: "function_models", subforem_id: nil)
        record.value = selections.to_h.stringify_keys
        record.save!
        clear_cache
        selections
      end
    end
  end
end
