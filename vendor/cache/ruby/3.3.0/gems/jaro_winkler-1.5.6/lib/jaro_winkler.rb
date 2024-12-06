# frozen_string_literal: true

require 'jaro_winkler/version'

if RUBY_ENGINE == 'ruby'
  begin
    require 'jaro_winkler/jaro_winkler_ext'
  rescue LoadError
    # Fall back to the pure implementation if the extension
    # can't be loaded for any reason (e.g. it was never built)
    require 'jaro_winkler/jaro_winkler_pure'
  end
else
  require 'jaro_winkler/jaro_winkler_pure'
end
