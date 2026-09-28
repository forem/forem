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
