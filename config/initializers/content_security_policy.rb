# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data
  policy.object_src  :none
  policy.script_src  :self, :https, :unsafe_inline
  policy.style_src   :self, :https, :unsafe_inline

  if Rails.env.development?
    # allow webpack-dev-server host as allowed origin for connect-src
    webpack_host = "#{ApplicationConfig.app_domain_no_port}:3035"
    policy.connect_src :self, :https, :unsafe_inline, "*.pusher.com", "http://#{webpack_host}", "ws://#{webpack_host}"
  else
    policy.connect_src :self, :https, :unsafe_inline, "*.pusher.com"
  end

  # Specify URI for violation reports
  policy.report_uri -> { "https://api.honeybadger.io/v1/browser/csp?api_key=#{ENV['HONEYBADGER_API_KEY']}&report_only=true&env=#{Rails.env}&context[user_id]=#{respond_to?(:current_user) ? current_user&.id : nil}" } # rubocop:disable Layout/LineLength
end

# If you are using UJS then enable automatic nonce generation
# Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
Rails.application.config.content_security_policy_report_only = true
