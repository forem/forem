module Ai
  ##
  # Resolves which model powers a given AI function.
  #
  # Admins choose a model option per function in Settings::AiFunctions. Resolution:
  #   1. Use the configured option when the function allows it and its API key is present.
  #   2. Otherwise use "default": the function's built-in Gemini behavior, unchanged.
  #
  # With nothing configured every function resolves to "default", so behavior is identical
  # to before this config existed.
  #
  # @example
  #   selection = Ai::FunctionConfig.selection_for(:article_spam_check)
  #   selection.jev?                    # => true when Jev is selected and TYPESAFE_API_KEY is set
  #   selection.gemini_model(fallback)  # => overridden Gemini model, or the fallback
  module FunctionConfig
    Option = Struct.new(:key, :provider, :jev_only, keyword_init: true)

    OPTIONS = {
      "default" => Option.new(key: "default", provider: :gemini, jev_only: false),
      "gemini_pro" => Option.new(key: "gemini_pro", provider: :gemini, jev_only: false),
      "gemini_lite" => Option.new(key: "gemini_lite", provider: :gemini, jev_only: false),
      "jev" => Option.new(key: "jev", provider: :typesafe, jev_only: true)
    }.freeze

    Selection = Struct.new(:function, :option, :provider, :model, keyword_init: true) do
      def jev?
        provider == :typesafe
      end

      def gemini?
        provider == :gemini
      end

      # The Gemini model to call: the admin override, else the function's own default.
      def gemini_model(builtin_model = Ai::Base::DEFAULT_MODEL)
        model || builtin_model
      end
    end

    class << self
      # @param function_key [Symbol, String] A key from Ai::FunctionRegistry.
      # @return [Selection]
      def selection_for(function_key)
        function = Ai::FunctionRegistry.fetch(function_key)
        option_key = Settings::AiFunctions.function_model(function.key)

        if option_key && option_key != "default" && !usable?(function, option_key)
          Rails.logger.warn("AI function #{function.key} is set to '#{option_key}' but it is unavailable; " \
                            "falling back to its default model")
          option_key = nil
        end

        build_selection(function, option_key || "default")
      end

      # Whether the function can run at all with the current keys and selection.
      def available?(function_key)
        option_available?(selection_for(function_key).option)
      end

      def jev?(function_key)
        selection_for(function_key).jev?
      end

      # For Gemini-only (generative) functions: the admin-selected Gemini model, or the
      # function's built-in default.
      def gemini_model_for(function_key, builtin_model = Ai::Base::DEFAULT_MODEL)
        selection_for(function_key).gemini_model(builtin_model)
      end

      # Options a function can be set to, in display order.
      def options_for(function)
        function = Ai::FunctionRegistry.fetch(function) unless function.is_a?(Ai::FunctionRegistry::Function)
        return [] unless function.configurable?

        OPTIONS.values.filter_map { |option| option.key if function.jev? || !option.jev_only }
      end

      def option_available?(option_key)
        case OPTIONS[option_key.to_s]&.provider
        when :gemini then Ai::Base::DEFAULT_KEY.present?
        when :typesafe then Ai::TypeSafe::Client::DEFAULT_KEY.present?
        else false
        end
      end

      def option_label(option_key)
        case option_key.to_s
        when "default" then "Default (built-in Gemini behavior)"
        when "gemini_pro" then "Gemini: #{Ai::Base::DEFAULT_MODEL}"
        when "gemini_lite" then "Gemini: #{Ai::Base::DEFAULT_LITE_MODEL}"
        when "jev" then "TypeSafe Jev: #{Ai::TypeSafe::Client::DEFAULT_MODEL}"
        end
      end

      def missing_key_for(option_key)
        case OPTIONS[option_key.to_s]&.provider
        when :gemini then "GEMINI_API_KEY"
        when :typesafe then "TYPESAFE_API_KEY"
        end
      end

      # Keeps only known functions with options they support. "default" entries are
      # dropped since an absent key already means default.
      #
      # @return [Hash{String => String}]
      def sanitize(selections)
        selections.to_h.each_with_object({}) do |(function_key, option_key), memo|
          next unless Ai::FunctionRegistry.key?(function_key)

          function = Ai::FunctionRegistry.fetch(function_key)
          option_key = option_key.to_s
          next if option_key == "default"
          next unless options_for(function).include?(option_key)

          memo[function.key.to_s] = option_key
        end
      end

      private

      def usable?(function, option_key)
        options_for(function).include?(option_key) && option_available?(option_key)
      end

      def build_selection(function, option_key)
        option = OPTIONS.fetch(option_key)
        model = case option_key
                when "gemini_pro" then Ai::Base::DEFAULT_MODEL
                when "gemini_lite" then Ai::Base::DEFAULT_LITE_MODEL
                when "jev" then Ai::TypeSafe::Client::DEFAULT_MODEL
                end

        Selection.new(function: function.key, option: option_key, provider: option.provider, model: model)
      end
    end
  end
end
