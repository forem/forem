# Set default Regexp timeout to protect against Regular Expression Denial of Service (ReDoS) attacks.
# Wrap in a `respond_to?` check to ensure compatibility with different Ruby versions.
# We use an ENV variable override `REGEXP_TIMEOUT` (default: 1.0) so it can be dynamically adjusted
# in production if a legitimate request experiences timeouts, avoiding emergency deployments.
# If REGEXP_TIMEOUT is explicitly set to blank, "nil", or "none", we disable the timeout (set to nil).
if Regexp.respond_to?(:timeout=)
  timeout_val = ENV.fetch("REGEXP_TIMEOUT", "1.0").to_s
  Regexp.timeout = if timeout_val.blank? || %w[nil none false].include?(timeout_val.downcase)
                     nil
                   else
                     begin
                       timeout = Float(timeout_val)
                       timeout.positive? ? timeout : 1.0
                     rescue ArgumentError, TypeError
                       1.0
                     end
                   end
end
