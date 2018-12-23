# Rails now embeds the expiry information also in encrypted or signed cookies value.
# Rails 5.2 cookies are not compatible with Rails 5.1 cookies
# This should be switched to true when confident that everything else works
# see https://guides.rubyonrails.org/upgrading_ruby_on_rails.html#expiry-in-signed-or-encrypted-cookie-is-now-embedded-in-the-cookies-values
Rails.application.config.action_dispatch.use_authenticated_cookie_encryption = false
