OmniAuth.config.logger = Rails.logger
OmniAuth.config.full_host = proc { URL.url }
# We can't use the 'omniauth-rails_csrf_protection' because of the custom way we
# handle CSRF Tokens in `config/initializers/persistent_csrf_token_cookie.rb`.
# Therefore we're manually taking the necessary steps to prevent CVE-2015-9284
# https://github.com/omniauth/omniauth/wiki/Resolving-CVE-2015-9284
OmniAuth.config.allowed_request_methods = [:post]
