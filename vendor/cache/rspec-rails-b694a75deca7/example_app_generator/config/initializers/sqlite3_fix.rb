if Rails.application.config.respond_to?(:active_record) && RUBY_ENGINE != "jruby"
  Rails.application.config.active_record.sqlite3.represent_boolean_as_integer = true
end
