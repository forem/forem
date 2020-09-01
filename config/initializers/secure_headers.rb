SecureHeaders::Configuration.default do |config|
  if Rails.env.production?
    config.csp = {
      default_src: %w(https: 'self'),
      font_src: %w('self' data: https:),
      img_src: %w('self' https: data:),
      object_src: %w('none'),
      script_src: %w(https: 'unsafe-inline'),
      connect_src: %w(connect-src 'self' 'unsafe-inline' *.pusher.com),
      style_src: %w('self' https: 'unsafe-inline')
    }
  end
end
