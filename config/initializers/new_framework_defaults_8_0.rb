# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 8.0 framework defaults upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `8.0`.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

# Specifies whether `to_time` methods preserve the UTC offset of their receivers or preserves the timezone.
# If set to `:zone`, `to_time` methods will use the timezone of their receivers.
# If set to `:offset`, `to_time` methods will use the UTC offset.
# If `false`, `to_time` methods will convert to the local system UTC offset instead.
Rails.application.config.active_support.to_time_preserves_timezone = :zone

# When both `If-Modified-Since` and `If-None-Match` are provided by the client
# only consider `If-None-Match` as specified by RFC 7232 Section 6.
# If set to `false` both conditions need to be satisfied.
Rails.application.config.action_dispatch.strict_freshness = true

# Set default Regexp timeout to protect against Regular Expression Denial of Service (ReDoS) attacks.
# Wrap in a `respond_to?` check to ensure compatibility with different Ruby versions.
# We use an ENV variable override `REGEXP_TIMEOUT` (default: 1.0) so it can be dynamically adjusted
# in production if a legitimate request experiences timeouts, avoiding emergency deployments.
# If REGEXP_TIMEOUT is explicitly set to blank, "nil", or "none", we disable the timeout (set to nil).
if Regexp.respond_to?(:timeout=)
  timeout_val = ENV.fetch("REGEXP_TIMEOUT", "1.0")
  Regexp.timeout = if timeout_val.blank? || %w[nil none false].include?(timeout_val.downcase)
                     nil
                   else
                     timeout_val.to_f
                   end
end
