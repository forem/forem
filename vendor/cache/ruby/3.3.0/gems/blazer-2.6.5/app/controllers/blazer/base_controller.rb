module Blazer
  class BaseController < ApplicationController
    # skip filters
    filters = _process_action_callbacks.map(&:filter) - [:activate_authlogic]
    skip_before_action(*filters, raise: false)
    skip_after_action(*filters, raise: false)
    skip_around_action(*filters, raise: false)

    clear_helpers

    protect_from_forgery with: :exception

    if ENV["BLAZER_PASSWORD"]
      http_basic_authenticate_with name: ENV["BLAZER_USERNAME"], password: ENV["BLAZER_PASSWORD"]
    end

    if Blazer.settings["before_action"]
      raise Blazer::Error, "The docs for protecting Blazer with a custom before_action had an incorrect example from August 2017 to June 2018. The example method had a boolean return value. However, you must render or redirect if a user is unauthorized rather than return a falsy value. Double check that your before_action works correctly for unauthorized users (if it worked when added, there should be no issue). Then, change before_action to before_action_method in config/blazer.yml."
    end

    if Blazer.before_action
      before_action Blazer.before_action.to_sym
    end

    if Blazer.override_csp
      after_action do
        response.headers['Content-Security-Policy'] = "default-src 'self' https: 'unsafe-inline' 'unsafe-eval' data:"
      end
    end

    layout "blazer/application"

    private

      def process_vars(statement, var_params = nil)
        var_params ||= request.query_parameters
        (@bind_vars ||= []).concat(statement.variables).uniq!
        # update in-place so populated in view and consistent across queries on dashboard
        @bind_vars.each do |var|
          if !var_params[var]
            default = statement.data_source.variable_defaults[var]
            # only add if default exists
            var_params[var] = default if default
          end
        end
        runnable = @bind_vars.all? { |v| var_params[v] }
        statement.add_values(var_params) if runnable
        runnable
      end

      def refresh_query(query)
        statement = query.statement_object
        runnable = process_vars(statement)
        cohort_analysis_statement(statement) if statement.cohort_analysis?
        statement.clear_cache if runnable
      end

      def add_cohort_analysis_vars
        @bind_vars << "cohort_period" unless @bind_vars.include?("cohort_period")
        @smart_vars["cohort_period"] = ["day", "week", "month"] if @smart_vars
        # TODO create var_params method
        request.query_parameters["cohort_period"] ||= "week"
      end

      def parse_smart_variables(var, data_source)
        smart_var_data_source =
          ([data_source] + Array(data_source.settings["inherit_smart_settings"]).map { |ds| Blazer.data_sources[ds] }).find { |ds| ds.smart_variables[var] }

        if smart_var_data_source
          query = smart_var_data_source.smart_variables[var]

          if query.is_a? Hash
            smart_var = query.map { |k,v| [v, k] }
          elsif query.is_a? Array
            smart_var = query.map { |v| [v, v] }
          elsif query
            result = smart_var_data_source.run_statement(query)
            smart_var = result.rows.map { |v| v.reverse }
            error = result.error if result.error
          end
        end

        [smart_var, error]
      end

      def cohort_analysis_statement(statement)
        @cohort_period = params["cohort_period"] || "week"
        @cohort_period = "week" unless ["day", "week", "month"].include?(@cohort_period)

        # for now
        @conversion_period = @cohort_period
        @cohort_days =
          case @cohort_period
          when "day"
            1
          when "week"
            7
          when "month"
            30
          end

        statement.apply_cohort_analysis(period: @cohort_period, days: @cohort_days)
      end

      # TODO allow all keys
      # or show error message for disallowed keys
      UNPERMITTED_KEYS = [:controller, :action, :id, :host, :query, :dashboard, :query_id, :query_ids, :table_names, :authenticity_token, :utf8, :_method, :commit, :statement, :data_source, :name, :fork_query_id, :blazer, :run_id, :script_name, :original_script_name]

      def variable_params(resource, var_params = nil)
        permitted_keys = resource.variables - UNPERMITTED_KEYS.map(&:to_s)
        var_params ||= request.query_parameters
        var_params.slice(*permitted_keys)
      end
      helper_method :variable_params

      def blazer_user
        send(Blazer.user_method) if Blazer.user_method && respond_to?(Blazer.user_method, true)
      end
      helper_method :blazer_user

      def render_errors(resource)
        @errors = resource.errors
        action = resource.persisted? ? :edit : :new
        render action, status: :unprocessable_entity
      end

      # do not inherit from ApplicationController - #120
      def default_url_options
        {}
      end
  end
end
