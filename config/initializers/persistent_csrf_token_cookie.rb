# config/initializers/monkey_patches/persistent_csrf_token_cookie.rb
#
# Workaround for CSRF protection bug.
#
# https://github.com/rails/rails/issues/21948
# The bug:
# The rails session cookie is not persistent,
# therefore it expires when the page is loaded from cache
# (i.e. when browser restores tabs on restart https://www.youtube.com/watch?v=bKDu0qMT4HM)
# which leads to an `InvalidAuthenticityToken` when the user submits a form from that page.
#
# Workaround:
# We decided to move the CSRF token from the session cookie into a separate persistent cookie.
module ActionController
  module RequestForgeryProtection
    COOKIE_NAME = :_csrf_token

    def real_csrf_token(session)
      csrf_token = cookies.encrypted[COOKIE_NAME] || session[:_csrf_token]
      csrf_token ||= SecureRandom.base64(AUTHENTICITY_TOKEN_LENGTH)
      cookies.encrypted[COOKIE_NAME] ||= {
        value: csrf_token,
        expires: 1.year.from_now,
        httponly: true
      }
      session[:_csrf_token] = csrf_token
      Base64.strict_decode64(csrf_token)
    end
  end
end

# http://blog.plataformatec.com.br/2013/08/csrf-token-fixation-attacks-in-devise/
# (devise-4.2.0/lib/devise/hooks/csrf_cleaner.rb):
Warden::Manager.after_authentication do |_record, warden, _options|
  clean_up_for_winning_strategy = !warden.winning_strategy.respond_to?(:clean_up_csrf?) ||
    warden.winning_strategy.clean_up_csrf?
  warden.cookies.delete(ActionController::RequestForgeryProtection::COOKIE_NAME) if Devise.clean_up_csrf_token_on_authentication && clean_up_for_winning_strategy
end
