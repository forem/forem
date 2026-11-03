module Middlewares
  # Fast-path Rack middleware for high-volume ApplicationMetalController telemetry endpoints:
  # - PATCH /bb_tabulations/:id (BillboardEventsController#update)
  # - POST /bb_tabulations, /billboard_events, /display_ad_events (BillboardEventsController#create)
  # - PUT/PATCH /page_views/:id (PageViewsController#update)
  # - POST /page_views (PageViewsController#create)
  #
  # Runs after Rack::Attack and Warden::Manager, and before Middlewares::SetSubforem,
  # Middlewares::SetCookieDomain, OmniAuth strategies, ActionDispatch::Journey routing,
  # and controller instantiation.
  class MetalTelemetryFastPath
    SKIP_METHODS = %w[GET HEAD OPTIONS].freeze
    CREATE_BILLBOARD_PATHS = Set.new(["/bb_tabulations", "/billboard_events", "/display_ad_events"]).freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      method = env[Rack::REQUEST_METHOD]
      return @app.call(env) if SKIP_METHODS.include?(method)

      path = env[Rack::PATH_INFO]
      route = ForemNative.match_metal_telemetry_route(method, path) || legacy_match_route(method, path)
      return @app.call(env) unless route

      kind, id_str = route
      case kind
      when :billboard_update
        handle_billboard_update(env, id_str)
      when :billboard_create
        handle_billboard_create(env)
      when :page_view_update
        handle_page_view_update(env, id_str)
      when :page_view_create
        handle_page_view_create(env)
      else
        @app.call(env)
      end
    end

    private

    def legacy_match_route(method, path)
      return unless method.is_a?(String) && path.is_a?(String)

      norm_path = path.bytesize > 1 && path.end_with?("/") ? path.chop : path
      case method
      when "PATCH"
        legacy_match_patch_route(norm_path)
      when "PUT"
        extract_prefix_id(norm_path, "/page_views/", :page_view_update)
      when "POST"
        return [:billboard_create, nil] if CREATE_BILLBOARD_PATHS.include?(norm_path)

        [:page_view_create, nil] if norm_path == "/page_views"
      end
    end

    def legacy_match_patch_route(norm_path)
      extract_prefix_id(norm_path, "/bb_tabulations/", :billboard_update) ||
        extract_prefix_id(norm_path, "/page_views/", :page_view_update)
    end

    def extract_prefix_id(norm_path, prefix, route_sym)
      return unless norm_path.start_with?(prefix)

      rest = norm_path.byteslice(prefix.bytesize, norm_path.bytesize - prefix.bytesize)
      [route_sym, rest] if valid_single_id_segment?(rest)
    end

    def valid_single_id_segment?(segment)
      !segment.empty? && segment.exclude?("/") && segment.exclude?(".")
    end

    def handle_billboard_update(env, id_str)
      is_embed = Billboard.embed_origin?(env["HTTP_ORIGIN"])
      return @app.call(env) if verify_csrf!(env, BillboardEventsController, skip: is_embed) == :defer

      skip_session_commit!(env)
      current_user_id = resolve_user_id(env, BillboardEventsController)
      rows_updated = BillboardEvent.add_impression_seconds(id: id_str, user_id: current_user_id)
      return head_response(200) if rows_updated.positive?

      billboard_event = BillboardEvent.select(:id, :category, :user_id, :updated_at).find_by(id: id_str)
      return head_response(404) unless billboard_event
      return head_response(200) unless billboard_event.category == BillboardEvent::CATEGORY_IMPRESSION
      return head_response(403) if billboard_event.user_id && billboard_event.user_id != current_user_id

      head_response(429)
    end

    def handle_billboard_create(env)
      is_embed = Billboard.embed_origin?(env["HTTP_ORIGIN"])
      return @app.call(env) if verify_csrf!(env, BillboardEventsController, skip: is_embed) == :defer

      skip_session_commit!(env)
      user_id = is_embed ? nil : resolve_user_id(env, BillboardEventsController)
      geolocation = resolve_geolocation(env, user_id, BillboardEventsController)

      if env[Rack::QUERY_STRING].blank? &&
          env["CONTENT_TYPE"].to_s.start_with?("application/json") &&
          (input = env[Rack::RACK_INPUT])
        raw_body = input.read
        input.rewind if input.respond_to?(:rewind)
        outcome = ForemNative.billboard_event_create_from_json_sql(
          raw_body, user_id, geolocation, env["HTTP_USER_AGENT"], is_embed, Time.current
        )
        if outcome == :blank_id
          return head_response(200)
        elsif outcome.is_a?(Array)
          sql_or_invalid, raw_billboard_id = outcome
          billboard_event_id = execute_billboard_insert(sql_or_invalid)
          enqueue_billboard_data_update(raw_billboard_id)
          return billboard_create_response(billboard_event_id)
        end
      end

      create_params = extract_billboard_params_from_request(env, user_id, geolocation, is_embed)
      raw_billboard_id = create_params[:billboard_id]
      return head_response(200) if raw_billboard_id.blank?

      billboard_event_id = BillboardEvent.create_with_async_commit(create_params)
      enqueue_billboard_data_update(raw_billboard_id)
      billboard_create_response(billboard_event_id)
    end

    def execute_billboard_insert(sql_or_invalid)
      return unless sql_or_invalid.is_a?(String)

      row = BillboardEvent.connection.exec_query(sql_or_invalid, "BillboardEvent Create").rows.first
      BillboardEvent.type_for_attribute(BillboardEvent.primary_key).cast(row.first) if row
    end

    def extract_billboard_params_from_request(env, user_id, geolocation, is_embed)
      req = ActionDispatch::Request.new(env)
      params = req.parameters
      raw_event = params["billboard_event"] || params["display_ad_event"]
      event_hash = raw_event.is_a?(Hash) ? raw_event : {}
      billboard_id = event_hash["billboard_id"].presence || event_hash["display_ad_id"]
      article_id = params["article_id"].presence || event_hash["article_id"]
      user_agent = event_hash["user_agent"].presence || params["user_agent"].presence || env["HTTP_USER_AGENT"]
      context_type = is_embed ? BillboardEvent::CONTEXT_TYPE_EMBED : event_hash["context_type"]

      {
        context_type: context_type,
        category: event_hash["category"],
        billboard_id: billboard_id,
        article_id: article_id,
        geolocation: geolocation,
        user_agent: user_agent,
        user_id: user_id
      }
    end

    def enqueue_billboard_data_update(raw_billboard_id)
      return if ApplicationConfig["DISABLE_BILLBOARD_DATA_UPDATE"] == "yes"

      throttle_minutes = (
        ApplicationConfig["BILLBOARD_EVENT_THROTTLE_TIME"] || BillboardEventsController::THROTTLE_TIME
      ).to_i
      ThrottledCall.perform("billboards_data_update-#{raw_billboard_id}", throttle_for: throttle_minutes.minutes) do
        Billboards::DataUpdateWorker.perform_async(raw_billboard_id)
      end
    end

    def billboard_create_response(billboard_event_id)
      if billboard_event_id
        [200, { "Content-Type" => "application/json; charset=utf-8" }, ["{\"id\":#{billboard_event_id}}"]]
      else
        head_response(200)
      end
    end

    def handle_page_view_update(env, id_str)
      return @app.call(env) if verify_csrf!(env, PageViewsController) == :defer

      skip_session_commit!(env)
      current_user_id = resolve_user_id(env, PageViewsController)
      Articles::PageViewUpdater.call(article_id: id_str, user_id: current_user_id) if current_user_id
      head_response(200)
    end

    def handle_page_view_create(env)
      return @app.call(env) if verify_csrf!(env, PageViewsController) == :defer

      skip_session_commit!(env)
      req = ActionDispatch::Request.new(env)
      raw_params = req.parameters
      page_view_params = raw_params.slice(
        "article_id", "viewable_type", "viewable_id", "referrer", "user_agent"
      )

      viewable_type = page_view_params[:viewable_type]
      viewable_id = page_view_params[:viewable_id]
      if viewable_type.blank? || viewable_id.blank? ||
          PageViewsController::ALLOWED_VIEWABLE_TYPES.exclude?(viewable_type) || viewable_id.to_i <= 0
        page_view_params.delete(:viewable_type)
        page_view_params.delete(:viewable_id)
      else
        page_view_params[:viewable_id] = viewable_id.to_i
      end

      current_user_id = resolve_user_id(env, PageViewsController)
      geo_region = env["HTTP_FASTLY_CLIENT_GEO_REGION"].presence ||
        resolve_geolocation(env, current_user_id, PageViewsController)
      page_view_params[:region] = geo_region

      if current_user_id
        page_view_params[:user_id] = current_user_id
      else
        page_view_params[:counts_for_number_of_views] =
          PageViewsController::VISITOR_IMPRESSIONS_AGGREGATE_COUNTS_FOR_NUMBER_OF_VIEWS
      end

      Articles::UpdatePageViewsWorker.perform_at(2.minutes.from_now, page_view_params)
      send_algolia_insight_if_needed(req, raw_params, current_user_id)
      head_response(200)
    end

    def send_algolia_insight_if_needed(req, raw_params, current_user_id)
      article_id = raw_params["article_id"]
      return unless article_id.present? && current_user_id

      passed_domain = raw_params["passed_domain"]
      raw_domain = if passed_domain.present? && passed_domain.exclude?("/") && passed_domain.exclude?(":")
                     passed_domain
                   else
                     req.host
                   end
      domain = ForemNative.subforem_request_domain(raw_domain) || raw_domain.sub(/:\d+\z/, "")
      RequestStore.store[:default_subforem_id] ||= Subforem.cached_default_id
      RequestStore.store[:subforem_id] ||= Subforem.cached_id_by_domain(domain)
      return unless Settings::General.algolia_application_id.present? && Settings::General.algolia_api_key.present?

      AlgoliaInsightsService.new.track_event(
        "view",
        "Article Viewed",
        current_user_id,
        article_id.to_i,
        "Article_#{Rails.env}",
        Time.current.to_i * 1000,
        nil,
        nil,
      )
    end

    def skip_session_commit!(env)
      session_opts = env[Rack::RACK_SESSION_OPTIONS]
      session_opts[:skip] = true if session_opts
    end

    def resolve_user_id(env, controller_class)
      if controller_class.instance_method(:session_current_user_id).owner != SessionCurrentUser
        return controller_class.allocate.session_current_user_id
      end

      session = env[Rack::RACK_SESSION]
      return unless session

      session["warden.user.user.key"]&.first&.first
    end

    def resolve_geolocation(env, user_id, controller_class)
      if controller_class.instance_method(:client_geolocation).owner != ApplicationMetalController
        return controller_class.allocate.client_geolocation
      end

      user_id ? env["HTTP_X_CLIENT_GEO"] : env["HTTP_X_CACHEABLE_CLIENT_GEO"]
    end

    def verify_csrf!(env, controller_class, skip: false)
      return :ok if skip || !forgery_protection_enabled?(controller_class)
      return :defer if controller_class.per_form_csrf_tokens
      return :defer if check_request_origin!(env) == :defer

      x_csrf_token = env["HTTP_X_CSRF_TOKEN"]
      encoded_real_token = extract_encoded_real_csrf_token(env)
      return :defer if !x_csrf_token.is_a?(String) || x_csrf_token.empty? || !encoded_real_token.is_a?(String)

      verified = ForemNative.verify_authenticity_token(x_csrf_token, encoded_real_token)
      return :defer if verified.nil?
      raise ActionController::InvalidAuthenticityToken unless verified

      :ok
    end

    def forgery_protection_enabled?(controller_class)
      controller_class.allow_forgery_protection &&
        controller_class._process_action_callbacks.any? { |cb| cb.filter == :verify_authenticity_token }
    end

    def extract_encoded_real_csrf_token(env)
      token = env[ActionController::RequestForgeryProtection::CSRF_TOKEN]
      return token if token

      token = env[Rack::RACK_SESSION]&.[]("_csrf_token")
      env[ActionController::RequestForgeryProtection::CSRF_TOKEN] = token if token
      token
    end

    def check_request_origin!(env)
      return :ok if Rails.env.test?

      referer = env["HTTP_REFERER"]
      origin = referer.present? ? nil : env["HTTP_ORIGIN"]
      native = if referer.present?
                 req = ActionDispatch::Request.new(env)
                 ForemNative.valid_request_origin(referer, nil, nil, req.host, req.port)
               elsif origin.nil?
                 true
               elsif origin == "null"
                 :null_origin
               else
                 req = ActionDispatch::Request.new(env)
                 ForemNative.valid_request_origin(nil, origin, req.base_url, nil, nil)
               end

      if native == :null_origin
        raise ActionController::InvalidAuthenticityToken, ApplicationController::NULL_ORIGIN_MESSAGE
      elsif native == false
        raise ActionController::InvalidAuthenticityToken
      elsif native.nil?
        return :defer
      end

      :ok
    end

    def head_response(status)
      [status, { "Content-Type" => "text/html" }, []]
    end
  end
end
