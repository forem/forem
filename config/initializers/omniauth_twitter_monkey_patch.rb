require "omniauth/strategies/twitter"

module OmniAuth
  module Strategies
    class Twitter < OmniAuth::Strategies::OAuth
      # Forem patched: `omniauth-twitter` 1.4.0 overrides `#callback_path` to parse
      # `URI(session['omniauth.params']['callback_url']).path` and `#callback_url` to
      # return `request.params['callback_url']` verbatim.
      #
      # Because `OmniAuth::Strategy#call!` evaluates `on_auth_path?` -> `on_callback_path?`
      # -> `callback_path` on every incoming Rack request before entering its rescue block,
      # any malformed `callback_url` query parameter stored in `session['omniauth.params']`
      # (from any OmniAuth request phase) raises an unhandled `URI::InvalidURIError` (or
      # `ArgumentError` / `NoMethodError`) on every subsequent request in that session.
      # It also causes the Twitter strategy to treat another provider's or arbitrary path's
      # `callback_url` as its own callback path, or forward an unvalidated `callback_url`.
      #
      # Remove `omniauth-twitter`'s `#callback_path` override so it inherits the canonical
      # `OmniAuth::Strategy#callback_path` (`/users/auth/twitter/callback`), and build
      # `callback_url` from `full_host`, `script_name`, and `callback_path` without query
      # parameters.
      remove_method :callback_path if method_defined?(:callback_path, false)

      def callback_url
        "#{full_host}#{script_name}#{callback_path}"
      end
    end
  end
end
