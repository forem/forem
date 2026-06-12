# Set default Regexp timeout to protect against Regular Expression Denial of Service (ReDoS) attacks.
# This setting is configured by default in Rails 8.0+.
# Forem implements it here as part of the preparation for Rails 8.0.
#
# Precautions:
# 1. We wrap it in a `respond_to?` check to ensure compatibility with different Ruby versions.
# 2. We use an ENV variable override `REGEXP_TIMEOUT` (default: 1.0) so it can be dynamically adjusted
#    in production if a legitimate request experiences timeouts, avoiding emergency deployments.
# 3. If REGEXP_TIMEOUT is explicitly set to blank, "nil", or "none", we disable the timeout (set to nil).
if Regexp.respond_to?(:timeout=)
  timeout_val = ENV.fetch("REGEXP_TIMEOUT", "1.0")
  Regexp.timeout = if timeout_val.blank? || %w[nil none false].include?(timeout_val.downcase)
                     nil
                   else
                     timeout_val.to_f
                   end
end
