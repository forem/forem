# Be sure to restart your server when you modify this file.
#
# This file eases your Rails 8.1 framework defaults upgrade.
#
# Uncomment each configuration one by one to switch to the new default.
# Once your application is ready to run with all new defaults, you can remove
# this file and set the `config.load_defaults` to `8.1` in config/application.rb.
#
# Read the Guide for Upgrading Ruby on Rails for more info on each option.
# https://guides.rubyonrails.org/upgrading_ruby_on_rails.html

# Controls whether `autocomplete="off"` is automatically added to hidden fields.
# If set to `true`, Rails stops forcing `autocomplete="off"` on hidden fields.
# Rails.application.config.action_view.remove_hidden_field_autocomplete = true

# Controls whether Active Record raises an error when order-dependent finder methods
# (such as `first` or `last`) are called without an explicit order on relations that
# lack a fallback order column.
# Rails.application.config.active_record.raise_on_missing_required_finder_order_columns = true

# Controls whether Action Controller relative redirects (e.g. `redirect_to "/path"`)
# raise an error, warn, or are allowed.
# Rails.application.config.action_controller.action_on_path_relative_redirect = :raise

# Controls whether HTML entities and other characters are escaped in JSON responses.
# If set to `false`, escaping is bypassed, which improves JSON serialization performance.
# Rails.application.config.action_controller.escape_json_responses = false

# Controls whether JS line/paragraph separators (U+2028 and U+2029) are escaped in JSON.
# If set to `false`, escaping is bypassed since modern browsers support these in JSON.
Rails.application.config.active_support.escape_js_separators_in_json = false
