module Middlewares
  # Fast-path Rack middleware for high-volume ApplicationMetalController telemetry endpoints:
  # - PATCH /bb_tabulations/:id (BillboardEventsController#update)
  # - POST /bb_tabulations, /billboard_events, /display_ad_events (BillboardEventsController#create)
  # - PUT/PATCH /page_views/:id (PageViewsController#update)
  # - POST /page_views (PageViewsController#create)
  # - POST /fallback_activity_recorder (GaEventsController#create)
  # - POST /feed_events (FeedEventsController#create)
  # - POST /feed_config_visits (FeedConfigVisitsController#create)
  #
  # Runs after Rack::Attack and Warden::Manager, and before Middlewares::SetSubforem,
  # Middlewares::SetCookieDomain, OmniAuth strategies, ActionDispatch::Journey routing,
  # and controller instantiation.
  class MetalTelemetryFastPath
    SKIP_METHODS = %w[GET HEAD OPTIONS].freeze
    CREATE_BILLBOARD_PATHS = Set.new(["/bb_tabulations", "/billboard_events", "/display_ad_events"]).freeze
    POST_STATIC_ROUTES = {
      "/page_views" => [:page_view_create, nil].freeze,
      "/fallback_activity_recorder" => [:ga_event_create, nil].freeze,
      "/feed_events" => [:feed_events_create, nil].freeze,
      "/feed_config_visits" => [:feed_config_visits_create, nil].freeze
    }.freeze
    NO_STORE_HEADERS = { "Cache-Control" => "private, no-store" }.freeze

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
      when :ga_event_create
        handle_ga_event_create(env)
      when :feed_events_create
        handle_feed_events_create(env)
      when :feed_config_visits_create
        handle_feed_config_visit_create(env)
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
        legacy_match_post_route(norm_path)
      end
    end

    def legacy_match_post_route(norm_path)
      return [:billboard_create, nil] if CREATE_BILLBOARD_PATHS.include?(norm_path)

      POST_STATIC_ROUTES[norm_path]
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

      current_user_id = resolve_user_id(env, BillboardEventsController)
      skip_session_commit!(env)
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

      user_id = is_embed ? nil : resolve_user_id(env, BillboardEventsController)
      skip_session_commit!(env)
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

    # Executes a prebuilt BillboardEvent INSERT SQL string with single-reconnect
    # retry on ActiveRecord::ConnectionFailed, returning the new primary key.
    def execute_billboard_insert(sql_or_invalid)
      return unless sql_or_invalid.is_a?(String)

      row = BillboardEvent.with_connection_retry do
        BillboardEvent.connection.exec_query(sql_or_invalid, "BillboardEvent Create")
      end.rows.first
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

      current_user_id = resolve_user_id(env, PageViewsController)
      skip_session_commit!(env)
      Articles::PageViewUpdater.call(article_id: id_str, user_id: current_user_id) if current_user_id
      head_response(200)
    end

    def handle_page_view_create(env)
      return @app.call(env) if verify_csrf!(env, PageViewsController) == :defer

      req = ActionDispatch::Request.new(env)
      raw_params = req.parameters
      page_view_params = raw_params.slice(
        "article_id", "viewable_type", "viewable_id", "referrer", "user_agent", "utm_source"
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
      skip_session_commit!(env)
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

      ensure_subforem_context!(req)
      return unless Settings::General.algolia_application_id.present? && Settings::General.algolia_api_key.present?

      AlgoliaInsights::TrackEventWorker.perform_async(
        "view",
        "Article Viewed",
        current_user_id,
        article_id.to_i,
        "Article_#{Rails.env}",
        Time.current.to_i * 1000,
        nil,
        nil,
        RequestStore.store[:subforem_id],
      )
    end

    def handle_ga_event_create(env)
      return @app.call(env) if verify_csrf!(env, GaEventsController) == :defer

      req = ActionDispatch::Request.new(env)
      ensure_subforem_context!(req)
      if Settings::General.ga_analytics_4_id.present? && Settings::General.ga_api_secret.present?
        raw_post = req.raw_post
        user_id = resolve_user_id(env, GaEventsController)
        skip_session_commit!(env)
        base_app_url = resolve_app_url(env)
        event_hash = parse_ga_event_payload(raw_post, base_app_url, user_id)
        return head_response(400) if event_hash == :invalid

        client_id = generate_anonymous_client_id(req)
        Ga::TrackEventWorker.perform_async(client_id, event_hash)
      else
        skip_session_commit!(env)
      end

      [200, { "Content-Type" => "text/plain; charset=utf-8" }, [""]]
    end

    def parse_ga_event_payload(raw_post, base_app_url, user_id)
      event_hash = ForemNative.extract_ga_event_params(raw_post, base_app_url, user_id)
      return event_hash unless event_hash.nil?

      json = JSON.parse(raw_post)
      return :invalid unless json.is_a?(Hash)

      referrer = json["referrer"]
      {
        "page_title" => json["document_title"],
        "page_location" => json["document_path"],
        "page_path" => json["path"],
        "user_id" => user_id,
        "user_language" => json["user_language"],
        "referrer" => referrer && !referrer.start_with?(base_app_url) ? referrer : nil,
        "user_agent" => json["user_agent"],
        "viewport_size" => json["viewport_size"],
        "screen_resolution" => json["screen_resolution"],
        "document_encoding" => json["document_encoding"],
        "data_source" => "web"
      }
    rescue JSON::ParserError
      :invalid
    end

    def resolve_app_url(env)
      custom_org = env["forem.custom_domain_org"]
      domain = custom_org ? custom_org.custom_domain : RequestStore.store[:subforem_domain]
      URL.url(nil, domain)
    rescue StandardError
      URL.url(nil, RequestStore.store[:subforem_domain])
    end

    def generate_anonymous_client_id(req)
      cookies = req.cookie_jar
      client_id = cookies[:client_id] || "#{scrambled_ip(req)[0..12]}.#{SecureRandom.uuid}"
      cookies[:client_id] = { value: client_id, expires: 1.year.from_now }
      client_id
    end

    def scrambled_ip(req)
      daily_key = Rails.cache.fetch("daily_random_key", expires_in: 48.hours) { SecureRandom.random_bytes(32) }
      crypt = ActiveSupport::MessageEncryptor.new(daily_key)
      crypt.encrypt_and_sign(req.env["HTTP_FASTLY_CLIENT_IP"] || req.remote_ip)
    end

    def handle_feed_events_create(env)
      req = ActionDispatch::Request.new(env)
      raw_params = req.parameters
      token_user_id = resolve_token_user_id(env, raw_params)
      csrf_status = verify_csrf!(
        env,
        FeedEventsController,
        skip: !token_user_id.nil?,
        fallback_token: raw_params["authenticity_token"],
      )
      return @app.call(env) if csrf_status == :defer

      current_user_id = token_user_id || resolve_user_id(env, FeedEventsController)
      skip_session_commit!(env)
      return head_response(200) if !current_user_id || FeatureFlag.enabled?(:disable_browser_feed_events)

      raw_events = raw_params["feed_events"]
      status = validate_feed_events_batch_status(raw_events)
      return head_response(status) if status

      if Rack::Attack.cache.count("feed_events/user/#{current_user_id}", 60) >
          FeedEventsController::REQUESTS_PER_MINUTE
        return [429, { "Content-Type" => "text/html", "Retry-After" => "60" }, []]
      end

      FeedEvents::BulkUpsert.call(slice_feed_events_params(raw_events, current_user_id))
      head_response(200)
    rescue ActionDispatch::Http::Parameters::ParseError
      skip_session_commit!(env)
      head_response(400)
    end

    def validate_feed_events_batch_status(raw_events)
      return 400 unless raw_events.is_a?(Array)
      return 413 if raw_events.size > FeedEventsController::MAX_BATCH_SIZE

      400 unless raw_events.all? { |ev| ev.is_a?(Hash) || ev.is_a?(ActionController::Parameters) }
    end

    def slice_feed_events_params(raw_events, current_user_id)
      raw_events.map do |event|
        raw = event.is_a?(ActionController::Parameters) ? event.to_unsafe_h : event
        raw.slice(
          *FeedEventsController::FEED_EVENT_ALLOWED_STRING_PARAMS,
          *FeedEventsController::FEED_EVENT_ALLOWED_PARAMS,
        ).merge(user_id: current_user_id)
      end
    end

    def handle_feed_config_visit_create(env)
      req = ActionDispatch::Request.new(env)
      raw_params = req.parameters
      token_user_id = resolve_token_user_id(env, raw_params)
      csrf_status = verify_csrf!(
        env,
        FeedConfigVisitsController,
        skip: !token_user_id.nil?,
        fallback_token: raw_params["authenticity_token"],
      )
      return @app.call(env) if csrf_status == :defer

      current_user_id = token_user_id || resolve_user_id(env, FeedConfigVisitsController)
      skip_session_commit!(env)
      return no_content_no_store_response unless current_user_id
      return no_content_no_store_response if FeatureFlag.enabled?(:disable_browser_feed_events)

      if Rack::Attack.cache.count("feed_config_visits/user/#{current_user_id}", 60) >
          FeedConfigVisitsController::REQUESTS_PER_MINUTE
        return [
          429,
          { "Content-Type" => "text/html", "Cache-Control" => "private, no-store", "Retry-After" => "60" },
          [],
        ]
      end

      visit_token = raw_params["visit_token"]
      event_id = raw_params["event_id"]
      unless visit_token.is_a?(String) && visit_token.bytesize <= 4096 && Feeds::RecordConfigVisit.valid_uuid?(event_id)
        return [400, { "Content-Type" => "text/html", "Cache-Control" => "private, no-store" }, []]
      end

      ensure_subforem_context!(req)
      next_visit_at = Feeds::RecordConfigVisit.call(
        token: visit_token, event_id: event_id, user_id: current_user_id, host: req.host,
      )
      return no_content_no_store_response unless next_visit_at

      wait_seconds = [next_visit_at - Time.current, 0].max.ceil.to_s
      [
        200,
        {
          "Content-Type" => "text/html",
          "Cache-Control" => "private, no-store",
          "X-Feed-Visit-Wait" => wait_seconds
        },
        [],
      ]
    rescue ActionDispatch::Http::Parameters::ParseError
      skip_session_commit!(env)
      [400, { "Content-Type" => "text/html", "Cache-Control" => "private, no-store" }, []]
    end

    def ensure_subforem_context!(req)
      passed_domain = req.GET["passed_domain"]
      raw_domain = if passed_domain.is_a?(String) && passed_domain.valid_encoding? && passed_domain.present?
                     passed_domain
                   else
                     req.host
                   end
      domain = ForemNative.subforem_request_domain(raw_domain) || legacy_subforem_request_domain(raw_domain)
      default_id = Subforem.cached_default_id
      subforem_id = Subforem.cached_id_by_domain(domain)
      RequestStore.store[:default_subforem_id] = default_id
      RequestStore.store[:subforem_id] = subforem_id
      RequestStore.store[:subforem_domain] = subforem_id.present? ? Subforem.cached_id_to_domain_hash[subforem_id] : nil
    end

    def legacy_subforem_request_domain(raw_domain)
      parsed_host = begin
        URI.parse(raw_domain).host
      rescue StandardError
        nil
      end
      parsed_host.presence ||
        raw_domain.gsub(%r{\Ahttps?://}, "").split("/").first&.split(":")&.first.presence || raw_domain
    end

    def skip_session_commit!(env)
      session_opts = env[Rack::RACK_SESSION_OPTIONS]
      session_opts[:skip] = true if session_opts
    end

    def resolve_token_user_id(env, raw_params)
      auth_header = env["HTTP_AUTHORIZATION"]
      jwt_param = raw_params&.[]("jwt")
      return unless auth_header || jwt_param

      token = if auth_header.present? && auth_header.start_with?("Bearer ")
                auth_header.split.last
              elsif jwt_param.present?
                jwt_param
              end
      return unless token.is_a?(String)

      payload = decode_auth_token(token)
      return unless payload && payload["user_id"]

      User.where(id: payload["user_id"]).pick(:id)
    end

    def decode_auth_token(token)
      native = ForemNative.verify_hs256_jwt(token, Rails.application.secret_key_base, Time.now.to_i)
      return if native == false
      return native if native

      JWT.decode(token, Rails.application.secret_key_base, true, algorithm: "HS256")[0]
    rescue StandardError
      nil
    end

    def resolve_user_id(env, controller_class)
      if controller_class.instance_method(:session_current_user_id).owner != SessionCurrentUser
        return controller_class.allocate.session_current_user_id
      end

      read_session_key(env, "warden.user.user.key")&.first&.first
    end

    def resolve_geolocation(env, user_id, controller_class)
      if controller_class.instance_method(:client_geolocation).owner != ApplicationMetalController
        return controller_class.allocate.client_geolocation
      end

      user_id ? env["HTTP_X_CLIENT_GEO"] : env["HTTP_X_CACHEABLE_CLIENT_GEO"]
    end

    def verify_csrf!(env, controller_class, skip: false, fallback_token: nil)
      return :ok if skip || !forgery_protection_enabled?(controller_class)
      return :defer if controller_class.per_form_csrf_tokens
      return :defer if check_request_origin!(env) == :defer

      x_csrf_token = env["HTTP_X_CSRF_TOKEN"].presence || fallback_token
      encoded_real_token = extract_encoded_real_csrf_token(env)
      return :defer if !x_csrf_token.is_a?(String) || x_csrf_token.empty? || !encoded_real_token.is_a?(String)

      verified = ForemNative.verify_authenticity_token(x_csrf_token, encoded_real_token)
      return :defer if verified.nil?

      unless verified
        skip_session_commit!(env)
        raise ActionController::InvalidAuthenticityToken
      end

      :ok
    end

    def forgery_protection_enabled?(controller_class)
      controller_class.allow_forgery_protection &&
        controller_class._process_action_callbacks.any? { |cb| cb.filter == :verify_authenticity_token }
    end

    def extract_encoded_real_csrf_token(env)
      token = env[ActionController::RequestForgeryProtection::CSRF_TOKEN]
      return token if token

      token = read_session_key(env, "_csrf_token")
      env[ActionController::RequestForgeryProtection::CSRF_TOKEN] = token if token
      token
    end

    def read_session_key(env, key)
      session = env[Rack::RACK_SESSION]
      return unless session

      session_opts = env[Rack::RACK_SESSION_OPTIONS]
      if session.respond_to?(:loaded?) && !session.loaded? && session_opts&.[](:skip)
        begin
          session_opts[:skip] = false
          session[key]
        ensure
          session_opts[:skip] = true
        end
      else
        session[key]
      end
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
        skip_session_commit!(env)
        raise ActionController::InvalidAuthenticityToken, ApplicationController::NULL_ORIGIN_MESSAGE
      elsif native == false
        skip_session_commit!(env)
        raise ActionController::InvalidAuthenticityToken
      elsif native.nil?
        return :defer
      end

      :ok
    end

    def head_response(status)
      [status, { "Content-Type" => "text/html" }, []]
    end

    def no_content_no_store_response
      [204, NO_STORE_HEADERS.dup, []]
    end
  end
end
