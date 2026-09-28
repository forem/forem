module Admin
  module Settings
    # Saves which model powers each AI function. See Ai::FunctionConfig.
    class AiFunctionsController < Admin::Settings::BaseController
      Result = Struct.new(:errors) do
        def success?
          errors.none?
        end
      end

      private

      def authorization_resource
        ::Settings::AiFunctions
      end

      # Unknown functions and options a function does not support are dropped rather than
      # stored, so a stale form can never select, say, Jev for a text-generation function.
      def upsert_config(settings)
        selections = Ai::FunctionConfig.sanitize(settings[:function_models].to_h)
        ::Settings::AiFunctions.set_global_function_models(selections)
        Result.new([])
      rescue ActiveRecord::RecordInvalid => e
        Result.new([e.message])
      end

      def settings_params
        params.require(:settings_ai_functions).permit(function_models: Ai::FunctionRegistry.configurable.map(&:key))
      end
    end
  end
end
